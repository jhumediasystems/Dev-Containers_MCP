# Resources

This directory is intended for external repositories or assets that power individual devcontainer examples. For the D1 to Neo4j workstation, clone your conversion toolkit here:

```
git clone <your-d1-to-neo4j-repo-url> d1-to-neo4j
```

The onCreate hook inside `examples/d1-to-neo4j` looks for `resources/d1-to-neo4j/requirements.txt` and optional helper scripts when bootstrapping the environment.
