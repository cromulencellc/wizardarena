defmodule Cgcef.ProgramHeader do
  alias Cgcef.File

  use Bitwise, skip_operators: true

  defstruct [:ptype, :offset, :vaddr, :paddr, :filesz, :memsz, :flags, :align]
  @type t :: %__MODULE__ {
    ptype: Types.uint32,
    offset: Types.uint32,
    vaddr: Types.uint32,
    paddr: Types.uint32,
    filesz: Types.uint32,
    memsz: Types.uint32,
    flags: Types.uint32,
    align: Types.uint32
  }

  @page_size 0x1000
  @decree_flag_addr 0x4347c000
  @decree_flag_size @page_size

  def verify(file, file_header) do
    results = (0..(file_header.phnum - 1))
    |> Enum.map(&verify_segment(file, file_header, &1))
    |> Enum.filter(fn(r) ->
      case r do
        :ok -> false
        _other -> true
      end
    end)

    case results do
      [] -> :ok
      [first | _rest] -> first
    end
  end

  defp verify_segment(_file, _file_header, 0) do
    :ok
  end

  defp verify_segment(file, file_header, header_num) do
    expected_pos = (file_header.phoff + (file_header.phentsize * header_num))

    p_header = file
    |> File.read_bytes(expected_pos, file_header.phentsize)
    |> build_ph

    cond do
      overlaps_decree_flag(p_header) ->
        mesg = "Program header #~B collides with flag page"
        |> :io_lib.format([header_num - 1])
        |> IO.chardata_to_string
        {:error, mesg}
      is_unrecognized_type(p_header.ptype) ->
        mesg = "Invalid program header #~B ~.16Bh."
        |> :io_lib.format([header_num - 1, p_header.ptype])
        |> IO.chardata_to_string
        {:error, mesg}
      true -> :ok
    end
  end

  defp overlaps_decree_flag(p_header) do
    vaddr_page = Bitwise.band(p_header.vaddr, -@page_size)

    vaddr_size = case p_header.memsz do
                   0 -> @page_size
                   other -> round_to_page(other)
                 end

    vaddr_b = vaddr_page
    vaddr_e = vaddr_page + vaddr_size

    dfp_b = @decree_flag_addr
    dfp_e = @decree_flag_addr + @decree_flag_size

    cond do
      # flag page start between segment start and end
      (vaddr_b <= dfp_b)   && (dfp_b   < vaddr_e) -> true
      # flag page end between segment start and end
      (vaddr_b <  dfp_e)   && (dfp_e   < vaddr_e) -> true
      # segment start between flag page start and end
      (dfp_b   <= vaddr_b) && (vaddr_b < dfp_e)   -> true
      # segment end between flag page start and end
      (dfp_b   <  vaddr_e) && (vaddr_e < dfp_e)   -> true

      # none of the above
      true -> false
    end
  end

  @ptypes [null: 0, load: 1, phdr: 6, pov2: 0x6ccccccc]

  defp is_unrecognized_type(type_code) do
    !List.keymember?(@ptypes, type_code, 1)
  end

  defp round_to_page(size) when 0 == rem(size, @page_size), do: 0
  defp round_to_page(size) do
    (size + @page_size) - rem(size, @page_size)
  end

  defp build_ph(<<
                ptype :: size(32)-little,
                offset :: size(32)-little,
                vaddr :: size(32)-little,
                paddr :: size(32)-little,
                filesz :: size(32)-little,
                memsz :: size(32)-little,
                flags :: size(32)-little,
                align :: size(32)-little
                >>) do
    %Cgcef.ProgramHeader{
      ptype: ptype,
      offset: offset,
      vaddr: vaddr,
      paddr: paddr,
      filesz: filesz,
      memsz: memsz,
      flags: flags,
      align: align
    }
  end

  def build_phs(file, file_header) do
    remain = file_header.phnum

    build_segment(file, file_header, remain, [])
  end

  defp build_segment(_file, _file_header, 0, accum) do
    Enum.reverse(accum)
  end

  defp build_segment(file, file_header, remain, accum) do
    offset = file_header.phoff + (file_header.phentsize * remain)

    p_header = file
    |> File.read_bytes(offset, file_header.phentsize)
    |> build_ph

    build_segment(file, file_header, remain - 1, [p_header | accum])
  end
end
