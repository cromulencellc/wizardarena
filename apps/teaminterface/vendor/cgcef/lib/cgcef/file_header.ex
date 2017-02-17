defmodule Cgcef.FileHeader do
  alias Cgcef.File

  defstruct [:eftype, :machine, :version, :entry, :phoff, :shoff, :flags,
             :ehsize, :phentsize, :phnum, :shentsize, :shnum, :shstrndx]
  @type t :: %__MODULE__ {
    eftype: Types.uint16,
    machine: Types.uint16,
    version: Types.uint32,
    entry: Types.uint32,
    phoff: Types.uint32,
    shoff: Types.uint32,
    flags: Types.uint32,
    ehsize: Types.uint16,
    phentsize: Types.uint16,
    phnum: Types.uint16,
    shentsize: Types.uint16,
    shnum: Types.uint16,
    shstrndx: Types.uint16
  }

  @padding_bytes 7
  @padding_bits @padding_bytes * 8
  @header_size 16 + 2*2 + 4*5 + 2*6

  def verify(file) do
    fh = build_fh(file)

    case verify_fh(fh) do
      :ok -> Cgcef.ProgramHeader.verify(file, fh)
      other -> other
    end
  end

  defp verify_fh(%Cgcef.FileHeader{} = hdr) do
    cond do
      @header_size != hdr.ehsize -> "invalid header size"
      2 != hdr.eftype -> "did not identify as executable"
      3 != hdr.machine -> "did not identify as i386"
      1 != hdr.version -> "did not identify as a version 1 binary"
      0 != hdr.flags -> "contained unsupported flags"
      0 == hdr.phnum -> "No program headers"
      32 != hdr.phentsize -> "Invalid program header size"
      true -> :ok
    end
  end

  def build_fh(<<
                 _padding :: size(@padding_bits),
                 eftype :: size(16)-little,
                 machine :: size(16)-little,
                 version :: size(32)-little,
                 entry :: size(32)-little,
                 phoff :: size(32)-little,
                 shoff :: size(32)-little,
                 flags :: size(32)-little,
                 ehsize :: size(16)-little,
                 phentsize :: size(16)-little,
                 phnum :: size(16)-little,
                 shentsize :: size(16)-little,
                 shnum :: size(16)-little,
                 shstrndx :: size(16)-little
                 >>) do
    %Cgcef.FileHeader{eftype: eftype,
                      machine: machine,
                      version: version,
                      entry: entry,
                      phoff: phoff,
                      shoff: shoff,
                      flags: flags,
                      ehsize: ehsize,
                      phentsize: phentsize,
                      phnum: phnum,
                      shentsize: shentsize,
                      shnum: shnum,
                      shstrndx: shstrndx}
  end

  def build_fh(file) do
    file
    |> File.read_bytes(9, @header_size - 9)
    |> build_fh
  end
end
