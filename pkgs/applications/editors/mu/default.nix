{ lib
, fetchFromGitHub
, qt5
, python3
, pythonRelaxDepsHook
, stdenv
# extra python packages to be included into the IDE's python env
, extraPackages ? (ps: [])
}:

let
  pyqt5Override = self: super: {
    pyqt5 = super.pyqt5.override { withSerialPort = true; };
  };

  python = python3.override {
    packageOverrides = pyqt5Override;
  };

  pythonUserEnv = python.withPackages (ps:
    propagatedBuildInputs
    ++ (extraPackages ps)
  );

  propagatedBuildInputs = with python.pkgs; [
    pyqt5
    qscintilla-qt5
    pyqtchart
    qtconsole
    adafruit-board-toolkit
    pyserial
    nudatus
    pyflakes
    pycodestyle
    black
    flask
    pgzero
    semver
    platformdirs
    virtualenv
    wheel
    requests
    ipykernel
    ipython-genutils
  ];

in python.pkgs.buildPythonApplication rec {
  pname = "mu-editor";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "mu-editor";
    repo = "mu";
    rev = "v${version}";
    sha256 = "sha256-VVhocM7xB2bRRv8rE6VPD2bEXAHBSyJgb/PcH9UIV7E=";
  };

  # never create a virtual environment, use nix instead like:
  # pkgs.mu-editor.override {
  #   extraPackages = ps: [ ps.package1 ps.package2 ];
  # }
  # This is achieved by:
  # - patching the virtual_environment.py's create() function to do nothing
  # - patching the virtual_environment.py's __init__() function to set the
  #   interpreter to the python executable set via NIX_PYTHONEXECUTABLE
  # - setting NIX_PYTHONEXECUTABLE in makeWrapperArgs to the python defined
  #   via nix.
  patches = [
    ./dont-use-virtualenv.patch
  ];

  buildInputs = lib.optional stdenv.isLinux qt5.qtwayland;

  pythonRelaxDeps = [
    "PyQt5"
    "QScintilla"
    "PyQtChart"
    "qtconsole"
  ];

  nativeBuildInputs = [
    qt5.wrapQtAppsHook
    pythonRelaxDepsHook
  ];

  inherit propagatedBuildInputs;

  dontWrapQtApps = true;

  doCheck = false;

  makeWrapperArgs = [
    "\${qtWrapperArgs[@]}"
    # sets sys.executable to the python with custom dependencies
    # This ensures that the correct python interpreter is used
    #   when the user executes the their program through the GUI
    "--set NIX_PYTHONEXECUTABLE ${pythonUserEnv}/bin/python"
  ];

  meta = with lib; {
    description = "A small, simple editor for beginner Python programmers. Written in Python and Qt5.";
    homepage = "https://codewith.mu/";
    license = with licenses; [ gpl3Plus ];
    maintainers = with maintainers; [ ];
  };
}
