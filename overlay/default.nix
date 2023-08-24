final: prev: {
  hyprland = prev.hyprland.override { enableNvidiaPatches = true; };
  mathematica = prev.mathematica.overrideAttrs (_: {
    postInstall = ''
      ln -s "$out/libexec/Mathematica/Executables/wolframscript" "$out/bin/wolframscript"
    '';
  });
  waybar = prev.waybar.overrideAttrs (old: {
    patches = [ ./waybar/waybar.patch ];
  });
}
