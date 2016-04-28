defmodule Mix.Tasks.Compile.NervesUart do
  @shortdoc "Compiles Nerves.UART C Code"

  def run(_) do
    File.mkdir("priv")
    {exec, args} = case :os.type do
      {:unix, os} when os in [:freebsd, :openbsd] ->
        {"gmake", ["all"]}
      _ ->
        {"make", ["all"]}
    end

    if System.find_executable(exec) do
      build(exec, args)
      Mix.Project.build_structure
      :ok
    else
      nocompiler_error(exec)
    end
  end

  def build(exec, args) do
    {result, error_code} = System.cmd(exec, args, stderr_to_stdout: true)
    IO.binwrite result
    if error_code != 0, do: build_error
  end

  defp nocompiler_error(exec) do
    raise Mix.Error, message: nocompiler_message(exec) <> help_message(:os.type)
  end
  defp build_error() do
    raise Mix.Error, message: build_message <> help_message(:os.type)
  end

  defp nocompiler_message(exec) do
    """
    Could not find the program `#{exec}`.

    You will need to install the C compiler `#{exec}` to be able to build
    Nerves.UART.

    """
  end

  defp build_message do
    """
    Could not compile Nerves.UART.

    Please make sure that you are using Erlang / OTP version 18.0 or later
    and that you have a C compiler installed.

    """
  end

  defp help_message({:win32, _}) do
    """
    You need to install MinGW and make sure that it is in your PATH. Test this by
    running `gcc --version` on the command line.

    If you do not have MinGW, one method to get it is to install it through
    Chocolatey. See http://chocolatey.org to install Chocolatey and run the
    following from and command prompt with administrative privileges:

    `choco install mingw`
    """
  end
  defp help_message(_) do
    """
    Please follow the directions below for the operating system you are
    using:

    Mac OS X: You need to have gcc and make installed. Try running the
    commands `gcc --version` and / or `make --version`. If these programs
    are not installed, you will be prompted to install them.

    Linux: You need to have gcc and make installed. If you are using
    Ubuntu or any other Debian-based system, install the packages
    `build-essential`. Also install `erlang-dev` package if not
    included in your Erlang/OTP version.

    """
  end
end

defmodule NervesUart.Mixfile do
  use Mix.Project

  @version "0.0.1"

  @description """
  Discover and use UARTs and serial ports in Elixir.
  """

  def project do
    [app: :nerves_uart,
     version: "0.0.1",
     elixir: "~> 1.2",
     name: "Nerves.UART",
     description: @description,
     package: package,
     source_url: "https://github.com/nerves-project/nerves_uart",
     compilers: [:nerves_uart] ++ Mix.compilers,
     docs: [extras: ["README.md"]],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:earmark, "~> 0.2", only: :dev},
      {:ex_doc,  "~> 0.11", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib", "c_src", "mix.exs", "Makefile*", "README.md", "LICENSE"],
      maintainers: ["Frank Hunleth"],
      licenses: ["Apache-2"],
      links: %{"GitHub" => "https://github.com/nerves-project/nerves_uart",
        "Docs" => "http://hexdocs.pm/nerves_uart"}
    ]
  end
end
