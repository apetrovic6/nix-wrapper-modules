{
  pkgs,
  self,
}:

let
  # Create a simple wrapper module
  helloModule = self.lib.wrapModule (
    { config, ... }:
    {
      config.package = config.pkgs.hello;
      config.flags = {
        "--greeting" = "initial";
      };
    }
  );

  # Apply with initial settings
  initialConfig = helloModule.apply {
    inherit pkgs;
    flags."--verbose" = { };
  };

  # Extend the configuration
  extendedConfig = initialConfig.extend {
    flags."--greeting" = "extended";
    flags."--extra" = "flag";
  };

  # Test mkForce to override a value
  forcedConfig = initialConfig.extend (
    { lib, ... }:
    {
      flags."--greeting" = lib.mkForce "forced";
      flags."--forced-flag" = { };
    }
  );

  # Test extending via wrapper.passthru.configuration.extend
  passthruExtendedConfig = initialConfig.wrapper.passthru.configuration.extend {
    flags."--passthru" = "test";
  };

in
pkgs.runCommand "extend-test" { } ''
  echo "Testing extend function..."

  initialScript="${initialConfig.wrapper}/bin/hello"
  extendedScript="${extendedConfig.wrapper}/bin/hello"
  forcedScript="${forcedConfig.wrapper}/bin/hello"
  passthruExtendedScript="${passthruExtendedConfig.wrapper}/bin/hello"

  # Check initial config has initial greeting
  if ! grep -q "initial" "$initialScript"; then
    echo "FAIL: initial config should have 'initial' greeting"
    cat "$initialScript"
    exit 1
  fi

  # Check initial config has verbose flag
  if ! grep -q -- "--verbose" "$initialScript"; then
    echo "FAIL: initial config should have --verbose"
    cat "$initialScript"
    exit 1
  fi

  # Check extended config has extended greeting (overriding initial)
  if ! grep -q "extended" "$extendedScript"; then
    echo "FAIL: extended config should have 'extended' greeting"
    cat "$extendedScript"
    exit 1
  fi

  # Check extended config has verbose flag (preserved from initial apply)
  if ! grep -q -- "--verbose" "$extendedScript"; then
    echo "FAIL: extended config should preserve --verbose"
    cat "$extendedScript"
    exit 1
  fi

  # Check extended config has extra flag (from extend)
  if ! grep -q -- "--extra" "$extendedScript"; then
    echo "FAIL: extended config should have --extra flag"
    cat "$extendedScript"
    exit 1
  fi

  # Check mkForce override works
  if ! grep -q "forced" "$forcedScript"; then
    echo "FAIL: forced config should have 'forced' greeting"
    cat "$forcedScript"
    exit 1
  fi

  # Check that mkForce overrode both initial and apply settings
  if grep -q "initial" "$forcedScript"; then
    echo "FAIL: forced config should not have 'initial' greeting (should be overridden by mkForce)"
    cat "$forcedScript"
    exit 1
  fi

  # Check forced config has forced-flag
  if ! grep -q -- "--forced-flag" "$forcedScript"; then
    echo "FAIL: forced config should have --forced-flag"
    cat "$forcedScript"
    exit 1
  fi

  # Check passthru.configuration.extend works
  if ! grep -q -- "--passthru" "$passthruExtendedScript"; then
    echo "FAIL: passthru extended config should have --passthru flag"
    cat "$passthruExtendedScript"
    exit 1
  fi

  # Check passthru extended config preserves original settings
  if ! grep -q -- "--verbose" "$passthruExtendedScript"; then
    echo "FAIL: passthru extended config should preserve --verbose"
    cat "$passthruExtendedScript"
    exit 1
  fi

  echo "SUCCESS: extend test passed"
  touch $out
''
