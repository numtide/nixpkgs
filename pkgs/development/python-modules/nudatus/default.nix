{ lib
, buildPythonPackage
, fetchFromGitHub
, setuptools
, wheel
}:

buildPythonPackage rec {
  pname = "nudatus";
  version = "0.0.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "zanderbrown";
    repo = "nudatus";
    rev = version;
    hash = "sha256-yNFidirDkf624Zta8hcG/b/Q5RDzPtoCHEepSXdARXA=";
  };

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  pythonImportsCheck = [ "nudatus" ];

  meta = with lib; {
    description = "Strip comments from python scripts";
    homepage = "https://github.com/zanderbrown/nudatus";
    changelog = "https://github.com/zanderbrown/nudatus/blob/${src.rev}/CHANGES.rst";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
