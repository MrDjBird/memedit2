# memedit

A iOS cheat engine with a memory editor and a Unity game inspector.

## Building

Build the rootless deb with:

```sh
MEMEDIT_RELEASE_BUILD=1 make clean package
```

Build only the universal arm64/arm64e dylib for jailed injection with:

```sh
make clean
MEMEDIT_RELEASE_BUILD=1 JAILED=1 make
```

The jailed artifact is written to `.theos/obj/memedit.dylib`.

Unity function hooks use Substrate and are available in the rootless tweak build
only. Installed hooks are restored by class name, method name, and parameter
count when IL2CPP becomes available.
