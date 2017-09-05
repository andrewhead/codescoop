Source for compiling the `database.jar` included in the
`libs` directory.  We separate this from the source for
`database-use` as Soot complains if we are including 
the compiled class *and* it can find the uncompiled `.java`
files on the classpath.

Compile with:
```bash
jar cvf program.jar -C .
```
