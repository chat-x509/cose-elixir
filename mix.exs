defmodule COSE.MixProject do
  use Mix.Project
  def application do [ extra_applications: [:logger, :crypto] ] end
  def project do
    [
      app: :cose,
      version: "0.11.20",
      description: "COSE  CXC 138 92 CBOR Object Signing and Encryption",
      deps: [
        {:ex_doc, ">= 0.0.0", only: :dev},
        {:b58, "~> 1.0"},
        {:cbor, "~> 1.0.0"},
        {:hkdf_erlang, "~> 0.1.1"}
      ],
      package: [
        name: :cose,
        files: ~w(lib mix.exs LICENSE README.md),
        licenses: ["MIT"],
        maintainers: ["Namdak Tonpa"],
        links: %{"GitHub" => "https://github.com/chat-x509/cose"}
      ],
    ]
  end
end
