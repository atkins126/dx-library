program ThreadClassesTests;
{

  Projet de test DUnit Delphi
  -------------------------
  Ce projet contient le framework de test DUnit et les ex�cuteurs de test GUI/Console.
  Ajoutez "CONSOLE_TESTRUNNER" � l'entr�e des d�finitions conditionnelles des options
  de projet pour utiliser l'ex�cuteur de test console.  Sinon, l'ex�cuteur de test GUI sera
  utilis� par d�faut.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  DX.Generics.Threading in 'DX.Generics.Threading.pas',
  DX.Generics.Threading.Tests.Dictionary in 'DX.Generics.Threading.Tests.Dictionary.pas',
  DX.Generics.Threading.Tests in 'DX.Generics.Threading.Tests.pas',
  DX.Generics.Threading.Tests.ObjectDictionary in 'DX.Generics.Threading.Tests.ObjectDictionary.pas',
  DX.Generics.Threading.Tests.List in 'DX.Generics.Threading.Tests.List.pas',
  DX.Generics.Threading.Tests.ObjectList in 'DX.Generics.Threading.Tests.ObjectList.pas';

{$R *.RES}

begin
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  DUnitTestRunner.RunRegisteredTests;

end.
