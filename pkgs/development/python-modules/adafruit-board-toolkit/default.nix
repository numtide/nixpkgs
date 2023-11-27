{ lib
, buildPythonPackage
, fetchPypi
, setuptools-scm
, wheel
, pyserial
}:

buildPythonPackage rec {
  pname = "adafruit-board-toolkit";
  version = "1.1.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-k8TwmztGnCqS6F5ZrXSBnefZzc2kvuUqYxGAejRAdsI=";
  };

  nativeBuildInputs = [
    setuptools-scm
    wheel
  ];

  propagatedBuildInputs = [
    pyserial
  ];

  pythonImportsCheck = [ "adafruit_board_toolkit" ];

  meta = with lib; {
    description = "CircuitPython board identification and information";
    homepage = "https://pypi.org/project/adafruit-board-toolkit";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
