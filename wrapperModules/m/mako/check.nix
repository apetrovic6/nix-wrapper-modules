{
  pkgs,
  self,
}:

let
  makoWrapped =
    (self.wrapperModules.mako.apply {
      inherit pkgs;
      "--config".content = ''
        ao=null
        vo=null
      '';
    }).wrapper;

in
if builtins.elem pkgs.stdenv.hostPlatform.system self.wrapperModules.mako.meta.platforms then
  pkgs.runCommand "mako-test" { } ''
    "${makoWrapped}/bin/mako" --help | grep -q "mako"
    touch $out
  ''
else
  pkgs.runCommand "mako-test-disabled" { } ''
    touch $out
  ''
