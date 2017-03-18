defmodule Nerves.UART.Mixfile do
  use Mix.Project

  @version "0.1.2"

  @description """
  Discover and use UARTs and serial ports in Elixir.
  """

  def project() do
    [app: :nerves_uart,
     version: @version,
     elixir: "~> 1.2",
     name: "Nerves.UART",
     description: @description,
     package: package(),
     source_url: "https://github.com/nerves-project/nerves_uart",
     docs: [extras: ["README.md"]],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()] ++ make_or_prebuilt()
  end

  # If the platform doesn't have make installed, try to
  # use a prebuilt version of the port binary
  defp make_or_prebuilt() do
    if run_make?() do
      [compilers: [:elixir_make] ++ Mix.compilers,
       make_executable: make_executable(),
       make_makefile: "Makefile",
       make_error_message: make_error_message(),
       make_clean: ["clean"]
      ]
    else
      [aliases: ["compile": ["compile", &copy_prebuilt/1]]]
    end
  end

  def application() do
    [applications: [:logger]]
  end

  defp deps() do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc,  "~> 0.11", only: :dev}
    ]
  end

  defp package() do
    [
      files: ["lib", "src/*.[ch]", "src/ei_copy/*.[ch]", "test",
              "mix.exs", "Makefile", "README.md", "LICENSE", "CHANGELOG.md"
              #   "prebuilt/nerves_uart.exe"
            ],
      maintainers: ["Frank Hunleth"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/nerves-project/nerves_uart"}
    ]
  end

  defp run_make?() do
    case :os.type() do
      {:win32, _} ->
        # If mingw32-make isn't installed, then try prebuilt version
        location = System.find_executable(make_executable())
        location != nil
      _ ->
        # Non-windows platforms should have make and gcc if they
        # have Elixir.
        true
    end
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

  defp copy_prebuilt(_) do
    case :os.type() do
      {:win32, _} ->
        Mix.shell.info("Copying prebuilt port binary")
        File.cp("prebuilt/nerves_uart.exe", "priv/nerves_uart.exe")
      _ ->
        Mix.raise("Couldn't find 'make' and no prebuilt port binary to use.")
    end
  end
end
