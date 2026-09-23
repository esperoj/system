.PHONY: ocaml ocaml-cfg
ocaml: sys-pkgs
	opam init --auto-setup -y
	eval $$(opam env)
	opam install -y ocaml-lsp-server ocp-indent odoc ocamlformat dune
ocaml-cfg: sys-pkgs-cfg
	@kv append "apt-pkgs" "opam "

