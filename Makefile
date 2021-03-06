
## Please feel free to modify following make variables
# BASEPATH: define prefix for all API paths. Can be changed to somthing like /mysvc/api
BASEPATH = "/api" #Please do not end with /

# SWAGGERPATH: define prefix for swagger documentation. Can be changed to somthing like /mysvc/swagger
SWAGGERPATH = "/swagger" #Please do not end with /

# PORT: define the TCP port for this application to listen on
PORT = "8080"

# VERSION: define the version of this service
VERSION := "v0.0.1"

##
# Please do not modify following make variables
BUILD := $(shell git rev-parse --short HEAD)-$(shell date +%Y%m%d%H%M%S)
PROJECTNAME := $(shell basename "$(PWD)")
MAKE := $(shell which make)

LDFLAGS=-ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD) -X=main.BasePath=$(BASEPATH) -X=main.Port=$(PORT) -X=main.SwaggerPath=$(SWAGGERPATH)"

prechecks:
	@echo "[ > ] Checking if go is installed"
	@[ `go version | grep version | wc -l | awk '{print $1}'` -eq 1 ] && { echo "[ PASS ] Golang is installed"; } || { echo "[ FAILED ] Golang is not installed. Refer to installation instructions here -> https://golang.org/dl/ "; }


dep:
	@echo "[ > ] Checking if dep is installed"
	@[ `$$GOBIN/dep version | grep platform | wc -l | awk '{print $1}'` -eq 1 ] && { echo "[ PASS ] Golang dep is installed"; } || { echo "[ FAILED ] Golang dep is not installed"; echo "[ TRY ] Attempting to install Golang dep tool"; set -x; go get -v -u  github.com/golang/dep/cmd/dep;  set +x;sync; [ `$$GOBIN/dep version | grep platform | wc -l | awk '{print $1}'` -eq 1 ] && { echo "[ PASS ] Golang dep is installed"; }; }
	@echo "[ > ] Updating dependencies"
	@set -x; [ -f Gopkg.toml ] ||  $$GOBIN/dep init -v
	@set -x; $$GOBIN/dep ensure -v

swag:
	@echo "[ > ] Checking if swag is installed"
	@[ `$$GOBIN/swag -v | grep  version| wc -l | awk '{print $1}'` -eq 1 ] && { echo "[ PASS ] Golang swag is installed"; } || { echo "[ FAILED ] Golang swag is not installed"; echo "[ TRY ] Attempting to install Golang swag tool"; set -x; cd $$GOPATH;go get -v -u github.com/swaggo/swag/cmd/swag;  set +x;sync; [ `$$GOBIN/swag -v | grep  version | wc -l | awk '{print $1}'` -eq 1 ] && { echo "[ PASS ] Golang swag is installed"; }; }
	@echo "[ > ] Updating swagger docs"
	@$$GOBIN/swag init

## run: Runs this project locally
run: swag
	@echo "[ > ] Starting application"
	@set -x; go run $(LDFLAGS) main.go

clean:
	@echo "[ > ] Cleaning build output dir"
	@sync;[ -f  build/out/${PROJECTNAME}  ] && { rm -f build/out/${PROJECTNAME}; echo "[ INFO ] DONE cleaning build/out"; } || { echo "[ INFO ] DONE cleaning build/out";}
	@echo "[ > ] Cleaning docker build dir"
	@sync;[ -f  build/docker/app/${PROJECTNAME}  ] && { rm -f build/docker/app/${PROJECTNAME}; echo "[ INFO ] DONE cleaning build/docker/app"; } || { echo "[ INFO ] DONE cleaning build/docker/app";}


## buildgo: Builds go image
buildgo: clean swag
	@echo "[ > ] Building go code"
	@set -x; go build $(LDFLAGS) -o build/out/${PROJECTNAME} main.go
	@set -x; ls -al build/out/${PROJECTNAME};

buildlinuxbin: clean swag
	@echo "[ > ] Building go code"
	@set -x; GOOS=linux GOARCH=amd64  go build $(LDFLAGS) -o build/out/${PROJECTNAME} main.go
	@set -x; ls -al build/out/${PROJECTNAME};

## builddocker: Builds docker images
builddocker: buildlinuxbin
	@echo "[ > ] Building docker image"
	@sync;set -x;cp build/out/${PROJECTNAME} build/docker/app/${PROJECTNAME}
	@set -x; ls -al build/docker/app/${PROJECTNAME}
	@sync;set -x; cd build/docker; docker build -t ${PROJECTNAME}:$(VERSION)-${BUILD} --build-arg BINNAME=${PROJECTNAME} .;
	@$(MAKE) clean

:
.PHONY: help
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo
