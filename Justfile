set export

@_default:
    just --list


bootstrap:
    git submodule update --init --recursive
    if test ! -e .venv; then \
      uv venv && uv pip install -r requirements.txt ; \
    fi
    pre-commit install

check-prettier:
    prettier "docs/**/*.md" --check

do-prettier:
    prettier -w "docs/**/*.md"


check-ruff:
    ruff check
    ruff format --check

do-ruff:
    ruff format

doc-serve: 
    mkdocs serve --livereload

# build the docs
docs:
    source .venv/bin/activate && \
    mkdocs build

[working-directory: 'libraries']
build_wrapper: 
    source ../.venv/bin/activate && \
    cmake -G Ninja -B.build -DCMAKE_BUILD_TYPE=Production && \ 
    cmake --build .build  

decrypt-sops:
    sops decrypt .sops/mongo.enc.yaml > .sops/mongo.yaml
    sops decrypt .sops/mongo_dev.enc.yaml > .sops/mongo_dev.yaml

encrypt-sops:
    sops encrypt .sops/mongo.yaml > .sops/mongo.enc.yaml
    sops encrypt .sops/mongo_dev.yaml > .sops/mongo_dev.enc.yaml


build_docker: build_wrapper
     docker build -t faktory_python -f ./docker/Dockerfile . 
     docker build -t faktory_prom -f ./docker/prometheus_reporting/Dockerfile . 

run_docker: 
    docker compose -f ./docker/docker-compose.yaml up -d --build 

stop_docker: 
    docker compose -f ./docker/docker-compose.yaml down

go: bootstrap docs build_wrapper build_docker run_docker
    echo "done!"
