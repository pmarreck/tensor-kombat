{
  description = "Tensor-Kombat: AI Debate Platform";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            # Build tools (compile-time)
            gcc
            pkg-config
          ];
          
          buildInputs = with pkgs; [
            # Core language and build tools
            idris2

            # C compilation dependencies for RefC backend
            gmp.dev  # Headers for GMP
            gmp      # Runtime library

            # CLI and utilities
            bash
            glow
            gum
            jq
            curl

            # Testing and development
            rlwrap

            # Version control
            jujutsu

            # HTTP client libraries for API calls
            cacert
          ];

          shellHook = ''
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            echo "Tensor-Kombat development environment loaded!"
            echo "Available tools:"
            echo "  - Idris 2: $(idris2 --version)"
            echo "  - GCC and GMP for RefC backend compilation"
            echo "  - Glow for markdown rendering"
            echo "  - Gum for interactive TUI"
            echo "  - jj for version control"
            echo "  - curl and jq for API testing"
            echo ""
            echo "Environment variables for AI APIs:"
            echo "  - ANTHROPIC_API_KEY (Claude)"
            echo "  - GOOGLE_GEMINI_API_KEY (Gemini)"
            echo "  - OPENAI_API_KEY (ChatGPT)"
            echo "  - GROK_API_KEY (Grok)"
            echo "  - GROQ_API_KEY (Groq)"
            echo ""
            echo "Run 'make test' to run the test suite"
            echo "Run 'make build' to build the project"
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "tensor-kombat";
          version = "0.1.0";

          src = ./.;

          nativeBuildInputs = with pkgs; [ 
            idris2 
            gcc 
            pkg-config
          ];
          
          buildInputs = with pkgs; [ 
            gmp.dev 
            gmp 
          ];

          buildPhase = ''
            idris2 --build tensor-kombat.ipkg
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp build/exec/* $out/bin/ || true
          '';
        };
      });
}
