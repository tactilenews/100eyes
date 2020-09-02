# 100eyes

100eyes ist die erste Open-Source-Lösung für dialoggetriebenen Journalismus in Deutschland. In der Redaktion ist 100eyes das Werkzeug, um möglichst viele unterschiedliche Menschen da zu erreichen, wo sie am liebsten erreicht werden wollen - per Telegram-Messenger oder E-Mail.

100eyes ist ein schlankes Tool, das die journalistische Routine verbessert: Redakteur\*innen können Fragen stellen und bekommen schneller Antworten von mehr Menschen. Die Benutzeroberfläche bietet Journalist\*innen zwei Kernfunktionen:

1. **Community pflegen**
   
2. **Recherchen starten:** Mit einem Klick können Journalist\*innen Fragen an ihre Community senden, alle Antworten gesammelt auswerten und neue Informationen aus den Antworten ihrer Nutzer\*innen strukturiert speichern.

## Demo
Hinter dem Projekt 100eyes stehen Astrid Csuraji und Dr. Jakob Vicari, die journalistische Innovationen vorantreiben. Wenn du gerne mehr erfahren möchtest oder daran interessiert bist, 100eyes für ein journalistisches Projekt zu verwenden, [vereinbare gerne einen Gesprächstermin](https://tactile.news/) mit uns.


## Installation

### Development
Zu Entwicklungszwecken kannst du 100eyes mithilfe von Docker aufsetzen. Das Docker-Setup solltest du unverändert nicht im Produktivbetrieb einsetzen. Um die folgenden Schritte ausführen zu können, muss Docker (inklusive Docker Compose) auf deinem Computer installiert sein. Installationsanleitungen hierzu findest du in der [Docker-Dokumentation](https://docs.docker.com/get-docker/). Außerdem benötigst du [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git), um dieses Repository zu klonen.

1. #### Repository klonen
   Klone dieses Repository. Hierzu kannst du entweder einen git-Client mit einer grafischen Oberfläche oder aber git direkt über die Kommandozeile verwenden:

   ```console
   $ git clone https://github.com/tactilenews/100eyes.git
   ```

2. #### Container bauen
   Wechsle in das Verzeichnis, in das du das Repository geklont hast und baue die Docker-Container mithilfe von Docker Compose:

    ```console
    $ cd ~/100eyes
    $ docker-compose build
    ```

3. #### Konfiguration
   100eyes basiert auf einigen Diensten, z.B. zum Versand und Empfang von E-Mails und Telegram-Nachrichten. Sensible Informationen wie z.B. API-Keys oder Passwörter speichert 100eyes verschlüsselt. Du kannst sie mithilfe des Rails-CLIs bearbeiten:
   
   ```console
   $ docker-compose run app bash
   $ EDITOR=vi bin/rails credentials:edit
   ```
   
   Für eine Übersicht über die verfügbaren Konfigurationsoptionen wirf einen Blick in die [Beispiel-Konfiguration](https://github.com/tactilenews/100eyes/tree/master/config/credentials/credentials.yml.enc).

4. #### Container starten
    Du kannst alle Container mit einem einzigen Befehl starten. 100eyes kannst du dann in deinem Browser unter http://localhost:3000 aufrufen.

    ```console
    $ docker-compose up
    ```

### Production
100eyes ist eine relativ einfache Ruby-on-Rails-Anwendung und besteht aus dem Anwendungsserver sowie einem Background-Worker zum Empfangen von eingehenden Telegram-Nachrichten.

* Ruby 2.7 (und das Bundler gem)
* PostgreSQL (Version 12+)
* nginx oder einen andere Reverse-Proxy

Unter [`/scripts`](https://github.com/tactilenews/100eyes/tree/master/scripts) findest du einige Skripte, die das Aufsetzen von 100eyes auf einem [Uberspace](https://uberspace.de) erleichtern.

## Förderung
Die Entwicklung von 100eyes wurde im Rahmen des [Prototype Funds](https://prototypefund.de) aus Mitteln des [Bundesministeriums für Bildung und Forschung](https://bmbf.de) gefördert.
