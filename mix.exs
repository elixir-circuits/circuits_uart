defmodule Circuits.UART.MixProject do
  use Mix.Project

  @version "1.3.0"

  @description "Discover and use UARTs and serial ports in Elixir."

  def project() do
    [
      app: :circuits_uart,
      version: @version,
      elixir: "~> 1.6",
      name: "Circuits.UART",
      description: @description,
      package: package(),
      source_url: "https://github.com/elixir-circuits/circuits_uart",
      docs: [extras: ["README.md"], main: "readme"],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_executable: make_executable(),
      make_makefile: "src/Makefile",
      make_error_message: make_error_message(),
      make_clean: ["clean"],
      make_env: make_env()
    ]
  end

  defp make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib"
        }

      _ ->
        %{}
    end
  end

  def application() do
    []
  end

  defp deps() do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "1.0.0-rc.4", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      files: [
        "lib",
        "src/*.[ch]",
        "src/ei_copy/*.[ch]",
        "src/Makefile",
        "test",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ],
      maintainers: ["Frank Hunleth"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/elixir-circuits/circuits_uart"}
    ]
  end

  defp make_executable() do
    case :os.type() do
      {:win32, _} ->
        "mingw32-make"

      _ ->
        :default
    end
  end

  @windows_mingw_error_msg """
  You may need to install mingw-w64 and make sure that it is in your PATH. Test this by
  running `gcc --version` on the command line.

  If you do not have mingw-w64, one method to install it is by using
  Chocolatey. See http://chocolatey.org to install Chocolatey and run the
  following from and command prompt with administrative privileges:

  `choco install mingw`
  """

  defp make_error_message() do
    case :os.type() do
      {:win32, _} -> @windows_mingw_error_msg
      _ -> :default
    end
  end
end
