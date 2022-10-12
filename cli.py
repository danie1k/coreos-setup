import json
import re
from operator import attrgetter
from pathlib import Path

import click
import jinja2
import mergedeep
import sh
import yaml

try:
  from yaml import CDumper as Dumper
except ImportError:
  from yaml import Dumper

CWD = Path.cwd()
FIX_CHMOD_REGEX = re.compile(r"mode:\s+([\"|'])([0-9]+)\1", re.MULTILINE)

SourceFile = dict[str, ...]
SourceFiles = tuple[SourceFile, ...]


class Builder:
  cwd: Path
  src: Path
  yq_path: Path
  out_path: Path

  build_variables: dict[str, ...]
  src_files: tuple[Path, ...]

  def __init__(self, *, src_path: Path, variables_path: Path, out_path: Path) -> None:
    self.src = src_path
    self.yq_path = CWD / "yq_linux_amd64"
    self.out_path = out_path

    self.build_variables = yaml.safe_load(variables_path.read_bytes())
    self.src_files = tuple(sorted(self.src.glob("*.yml"), key=attrgetter("name")))

  def load_source_files(self) -> tuple[str, ...]:
    return tuple(file_path.read_text() for file_path in self.src_files)

  def process_source_files(self, source_files: tuple[str, ...]) -> SourceFiles:
    environment = jinja2.Environment(loader=jinja2.FileSystemLoader(self.src.absolute()))
    environment.filters["as_list"] = _as_list

    result = []
    for raw_text in source_files:
      processed_text = environment.from_string(raw_text).render(self.build_variables)
      result.append(yaml.safe_load(processed_text))

    return tuple(result)

  def merge_source_files(self, source_files: SourceFiles) -> SourceFile:
    return mergedeep.merge(*source_files, strategy=mergedeep.Strategy.ADDITIVE)

  def source_to_yaml(self, source: SourceFile) -> str:
    yq = sh.Command(str(self.yq_path.absolute()))
    result = yq("--no-colors", "--prettyPrint", "-", _in=json.dumps(source).encode())

    almost_ready = result.stdout.decode("utf-8")
    return self._fix_chmod_value(almost_ready)

  def write_out_yaml(self, data: str) -> None:
    self.out_path.write_text(data)

  def _fix_chmod_value(self, yaml_text: str) -> str:
    result = FIX_CHMOD_REGEX.sub("mode: \\2", yaml_text)
    if result:
        return result
    raise RuntimeError("Unable to _fix_chmod_value")


def _as_list(value: list[str]) -> str:
  result = ", ".join(map(lambda item: f'"{item}"', value))
  return f"[{result}]"


@click.group()
def cli() -> None:
  pass


@cli.command()
@click.option(
  "--src",
  help="Path to directory with source YAML files",
  type=click.Path(exists=True, file_okay=False, dir_okay=True, resolve_path=True),
  required=True,
  default="./src",
  show_default=True,
)
@click.option(
  "--variables",
  help="Variables subst YAML file",
  type=click.Path(exists=True, file_okay=True, dir_okay=False, resolve_path=True),
  required=True,
  default="./config/build-variables.yml",
  show_default=True,
)
@click.option(
  "--out",
  help="Result YAML file path",
  type=click.Path(exists=False, file_okay=True, dir_okay=False, resolve_path=True, writable=True),
  required=True,
  default="./build/out.yml",
  show_default=True,
)
def build(src: str, variables: str, out: str) -> None:
  """
  Build multiple source YAML files into single Butane YAML file.
  """
  builder = Builder(
    src_path=Path(src),
    variables_path=Path(variables),
    out_path=Path(out),
  )

  raw_sources = builder.load_source_files()
  processed_sources = builder.process_source_files(raw_sources)
  merged_source = builder.merge_source_files(processed_sources)
  out = builder.source_to_yaml(merged_source)

  builder.write_out_yaml(out)

  click.echo(f"File {builder.out_path.absolute()} saved.")
  _src_files = '\n  - '.join(map(str, builder.src_files))
  click.echo(f"Processed source files:\n  - {_src_files}")


@cli.command()
@click.option(
  "--src",
  help="Path to source Butane YAML file",
  type=click.Path(exists=True, file_okay=True, dir_okay=False, resolve_path=True),
  required=True,
  default="./build/out.yml",
  show_default=True,
)
@click.option(
  "--out",
  help="Result Ignition (JSON) file path",
  type=click.Path(exists=False, file_okay=True, dir_okay=False, resolve_path=True, writable=True),
  required=True,
  default="./build/out.json",
  show_default=True,
)
def compile(src: str, out: str) -> None:
  """
  Compile Butane source YAML file into Ignition file.
  """
  try:
    result = sh.docker(
      "run",
      "--rm",
      "-v", f"{src}:/butane.yml",
      "quay.io/coreos/butane:release",
      "--strict",
      "--pretty",
      "/butane.yml",
    )
  except sh.ErrorReturnCode as exc:
    raise click.ClickException(exc.stderr.decode())

  Path(out).write_bytes(result.stdout)
  click.echo(f"File {out} saved.")


if __name__ == '__main__':
  cli()
