APP      := vdisplay
SRC      := Sources/main.swift

all: $(APP)

$(APP): $(SRC)
	swiftc -O -o $(APP) $(SRC)

clean:
	rm -f $(APP)
