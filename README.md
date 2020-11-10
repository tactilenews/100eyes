# 100eyes (English version below)

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
   100eyes basiert auf einigen Diensten, z.B. zum Versand und Empfang von E-Mails und Telegram-Nachrichten. Sensible Informationen wie z.B. API-Keys oder Passwörter kannst du mithilfe von Umgebungsvariablen setzen. Dazu kopierst du dir am Besten die dazu vorgesehene Schablone:

   ```bash
   $ cp .env.template .env
   ```

   Und editierst die neue Datei `.env` und fügst dort API-Schlüssel und weitere Secrets hinzu. Diese Datei `.env` wird von `git` ignoriert.

4. #### Container starten
    Du kannst alle Container mit einem einzigen Befehl starten. 100eyes kannst du dann in deinem Browser unter http://localhost:3000 aufrufen.

    ```console
    $ docker-compose up
    ```

  ##### Webpack Development Server

  Mit diesem Befehl kannst du zu Entwicklungszwecken das Kompilieren der Assets beschleunigen (z.B. bei vielen Änderungen an CSS Dateien):

  ```console
  $ docker-compose exec app bin/webpack-dev-server
  ```

### Production
100eyes ist eine relativ einfache Ruby-on-Rails-Anwendung und besteht aus dem Anwendungsserver sowie einem Background-Worker zum Empfangen von eingehenden Telegram-Nachrichten.

* Ruby 2.7 (und das Bundler gem)
* PostgreSQL (Version 12+)
* nginx oder einen andere Reverse-Proxy

Unter [`/scripts`](https://github.com/tactilenews/100eyes/tree/master/scripts) findest du einige Skripte, die das Aufsetzen von 100eyes auf einem [Uberspace](https://uberspace.de) erleichtern.

## Förderung
Die Entwicklung von 100eyes wurde im Rahmen des [Prototype Funds](https://prototypefund.de) aus Mitteln des [Bundesministeriums für Bildung und Forschung](https://bmbf.de) gefördert. Das [Medieninnovationszentrum Babelsberg](http://miz-babelsberg.de) fördert die Entwicklung zusätzlicher Module.

## Lizenz
100eyes wird von [tactile.news](https://tactile.news) entwickelt und ist unter der [MIT-Lizenz](https://github.com/tactilenews/100eyes/blob/master/LICENSE) lizenziert.
Die Entwicklung von 100eyes wurde im Rahmen des [Prototype Funds](https://prototypefund.de) aus Mitteln des [Bundesministeriums für Bildung und Forschung](https://bmbf.de) gefördert.


## English version

# 100eyes

100eyes is the first open source solution for dialog-driven journalism in Germany. In the editorial office, 100eyes is the tool to reach as many different people as possible where they would most like to be reached - via telegram messenger or e-mail.

100eyes is a lean tool that improves journalistic routine: editors\* can ask questions and get answers from more people faster. The user interface offers two core functions to journalists:

1. maintain **community**

2 **Start research:** With just one click, journalists can send questions to their community, evaluate all answers collectively and store new information from the answers of their users in a structured way.

## Demo
Behind the 100eyes project are Astrid Csuraji and Dr. Jakob Vicari, who are driving journalistic innovation. If you would like to learn more or are interested in using 100eyes for a journalistic project, [please contact us at https://tactile.news/].


## Installation

### Development
For development purposes, you can set up 100eyes using Docker. You should not use the Docker setup in production mode. To perform the following steps, Docker (including Docker Compose) must be installed on your computer. You can find installation instructions for this in the [Docker Documentation](https://docs.docker.com/get-docker/). You will also need [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) to clone this repository.

1. #### Clone the repository
   Clone this repository. You can either use a git client with a graphical interface or use git directly from the command line:

   ``console
   $ git clone https://github.com/tactilenews/100eyes.git
   ```

2. #### Building containers
   Change to the directory where you cloned the repository and build the Docker containers using Docker Compose:

    ``console
    $ cd ~/100eyes
    $ docker-compose build
    ```

3. #### Configuration
   100eyes is based on some services, e.g. for sending and receiving e-mails and telegram messages. You can set sensitive information such as API keys or passwords using environment variables. To do this, it is best to copy the template provided for this purpose:

   ``bash
   $ cp .env.template .env
   ```

   And edit the new .env file and add API keys and other secrets there. This file `.env` is ignored by `git`.

4. #### Start container
    You can start all containers with a single command. 100eyes can then be viewed in your browser at http://localhost:3000.

    ``console
    $ docker-compose up
    ```

  ##### Webpack Development Server

  With this command you can speed up the compilation of the assets for development purposes (e.g. for many changes to CSS files):

  ``console
  $ docker-compose exec app bin/webpack-dev-server
  ```

### Production
100eyes is a relatively simple Ruby-on-Rails application and consists of the application server and a background worker to receive incoming telegram messages.

* Ruby 2.7 (and the bundler gem)
* PostgreSQL (Version 12+)
* nginx or another reverse proxy

At [`/scripts`](https://github.com/tactilenews/100eyes/tree/master/scripts) you can find some scripts that make it easier to set up 100eyes on an [Uberspace](https://uberspace.de).

## Promotion
The development of 100eyes was supported by the [Prototype Fund](https://prototypefund.de) with funds from the [Federal Ministry of Education and Research](https://bmbf.de).


