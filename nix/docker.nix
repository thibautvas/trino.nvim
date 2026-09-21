{
  docker,
  writeShellApplication,
}:

writeShellApplication {
  name = "run-trino";
  runtimeInputs = [ docker ];
  text = "docker run -d --name trino -p 8080:8080 trinodb/trino";
}
