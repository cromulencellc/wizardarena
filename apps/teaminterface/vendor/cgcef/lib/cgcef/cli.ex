defmodule Cgcef.Cli do
  def main(args) do
    args
    |> OptionParser.parse(strict: [verbose: :boolean,
                                   only_analyze: :boolean,
                                   help: :boolean],
                          aliases: ['only-analyze': :only_analyze])
    |> run
  end

  defp run({_args, [], _invalid}) do
    puts ~s"""
Usage: cgcef [--help] [--verbose] [--only-analyze | --only_analyze] path.cgc
Analyze a CGC executable.

Without arguments, exits with zero status if valid, exits non-zero with error
message to stdout.

 --help: this screen
 --verbose: verify file is a CGC executable, and print analysis to stderr
 --only-analyze: print analysis of possibly-invalid CGC executable to stderr
"""
  end

  defp run({args, [filename], []}) do
    cond do
      List.keymember?(args, :help, 0) -> run({[], [], []})
      List.keymember?(args, :only_analyze, 0) -> analyze(filename)
      List.keymember?(args, :verbose, 0) -> verbose(filename)
      true -> normal(filename)
    end
  end

  defp run({_args, _filename, [_invalid | _moar]}) do
    run({[], [], []})
  end

  defp normal(filename) do
    case Cgcef.verify(filename) do
      :ok -> 0
      {:error, error_mesg} -> error(filename, error_mesg)
    end
  end

  defp analyze(filename) do
    analysis = filename
    |> Cgcef.analyze

    case analysis do
      {:error, err} -> error(filename, err)
      success = %Cgcef{} -> IO.inspect(success, pretty: true, base: :hex)
    end
  end

  defp verbose(filename) do
    # first pass is validation
    case Cgcef.verify(filename) do
      :ok -> analyze(filename)
      {:error, error_mesg} -> error(filename, error_mesg)
    end
  end

  defp error(filename, error_mesg) when is_binary(error_mesg) do
    formatted_mesg = "~s: ~s"
    |> :io_lib.format([filename, error_mesg])

    puts formatted_mesg
    System.halt(1)
  end

  defp error(filename, error_mesg) do
    formatted_mesg = "~s: ~p"
    |> :io_lib.format([filename, error_mesg])

    puts formatted_mesg
    System.halt(1)
  end

  defp puts(mesg) do
    IO.puts(:standard_error, mesg)
  end
end
