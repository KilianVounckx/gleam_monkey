# Run a debug build
run:
    gleam run

# Compile the app to erlang
build:
    gleam build --warnings-as-errors

# Run unit and cram tests
test:
    gleam test
    cram -E -i cram/*.t
