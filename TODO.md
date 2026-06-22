Verifikation — empfohlene Schritte

Bevor du committest, lass den Render-Smoketest laufen:

    just render-test

Die Recipe rendert drei Copier-Szenarien (Claude-only ohne Sandbox + Full-Stack mit Langfuse/Crawl4AI + Full-Stack mit MLflow) und validiert die JSON-Outputs sowie `docker compose config` mit beiden Profilen aktiv — sodass profil-gegatete Services und `:?`-Guards tatsächlich evaluiert werden.

Falls der JSON-Schritt scheitert: das `tojson`-Filter oder die `loop.last`-Kommata wurden vom Renderer anders interpretiert als gedacht — sag Bescheid, dann gehe ich punktgenau drauf.
