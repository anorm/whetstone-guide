SOURCE_DIR=./scad
STL_DIR=./stl
PREVIEW_DIR=./preview

SOURCES  =$(wildcard $(SOURCE_DIR)/*.scad)
STLS     =$(patsubst $(SOURCE_DIR)/%.scad, $(STL_DIR)/%.stl,     $(SOURCES))
PREVIEWS =$(patsubst $(SOURCE_DIR)/%.scad, $(PREVIEW_DIR)/%.png, $(SOURCES))

.PHONY: all clean

all: $(STLS) $(PREVIEWS)

clean:
	-rm $(STL_DIR)/* $(PREVIEW_DIR)/*

$(STL_DIR):
	mkdir -p $(STL_DIR)

$(PREVIEW_DIR):
	mkdir -p $(PREVIEW_DIR)

$(STL_DIR)/%.stl: $(SOURCE_DIR)/%.scad | $(STL_DIR)
	openscad -o $@ --backend Manifold $<

$(PREVIEW_DIR)/%.png: $(SOURCE_DIR)/%.scad | $(PREVIEW_DIR)
	openscad -o $@ \
		--backend Manifold \
		--colorscheme "Tomorrow Night" \
		--camera=-1.15764,9.36881,22.9824,78.1,0,241.5,363.292 \
		--imgsize 1920,1080 \
		$<

