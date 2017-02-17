defmodule Cgcef do
  alias Cgcef.File

  defstruct [:magic, :class, :endianness, :version, :abi, :abi_version,
             :file_header, :program_headers]
  @type t :: %__MODULE__{
    magic: <<_::32>>,
    class: byte,
    endianness: byte,
    version: byte,
    abi: byte,
    abi_version: byte,
    file_header: Cgcef.FileHeader.t,
    program_headers: [Cgcef.ProgramHeader.t]
  }

  def analyze(file) when is_pid(file) do
    ident_ef = build_ident(File.read_bytes(file, 0, 9))
    file_ef = %{ident_ef | file_header: Cgcef.FileHeader.build_fh(file)}
    prog_ef = %{file_ef | program_headers:
                Cgcef.ProgramHeader.build_phs(file, file_ef.file_header)}

    prog_ef
  end

  def analyze(filename) when is_binary(filename) do
    File.open(filename, fn(f) ->
      analyze(f)
    end)
  end

  def verify(file) when is_pid(file) do
    verify_magic(file)
  end

  def verify(filename) when is_binary(filename) do
    File.open(filename, fn(f) -> verify(f); end)
  end

  defp verify_magic(file) do
    case File.read_bytes(file, 0, 4) do
      "\x7fCGC" -> verify_metadata(file)
      <<_first::bytes-size(1), sig::bytes-size(3)>> ->
        mesg = "did not identify as a DECREE binary (ident ~s)"
        |> :io_lib.format([sig])
        |> IO.chardata_to_string
        {:error, mesg}
    end
  end

  defp verify_metadata(file) do
    <<class, endianness, version, abi, abi_version>> = IO.binread(file, 5)

    cond do
      1 != class -> {:error, "did not identify as a 32bit binary"}
      1 != endianness -> {:error, "did not identify as little endian"}
      1 != version -> {:error, "unknown CGCEF version"}
      0x43 != abi -> {:error, "did not identify as DECREE ABI"}
      1 != abi_version -> {:error, "did not identify as v1 DECREE ABI"}
      true -> verify_headers(file)
    end
  end

  defp verify_headers(file) do
    Cgcef.FileHeader.verify(file)
  end

  defp build_ident(<<
                   magic :: bytes-size(4),
                   class,
                   endianness,
                   version,
                   abi,
                   abi_version
                >>) do
    %Cgcef{magic: magic,
           class: class,
           endianness: endianness,
           version: version,
           abi: abi,
           abi_version: abi_version}
  end
end
