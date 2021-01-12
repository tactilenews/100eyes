# `100eyes`

`100eyes` is the first open source solution for dialog-driven journalism in Germany. In the editorial office, `100eyes` enables newsrooms to reach as many people as possible where they would most like to be reached - via Telegram messenger or e-mail.

`100eyes` is a lean tool that improves journalistic routine: editors can ask questions and get answers from more people faster. The user interface offers two core functions to journalists:

1. Maintain a **community**

2. **Start research:** With just one click, journalists can send questions to their community, evaluate all answers collectively and store new information from the answers of their contributors in a structured way.

## Demo
Behind the `100eyes` project are Astrid Csuraji and Dr. Jakob Vicari, who are driving journalistic innovation. If you would like to learn more or are interested in using `100eyes` for a journalistic project, please contact us at https://tactile.news/.

## Installation

## Development
For development purposes, you can set up `100eyes` using Docker. To perform the following steps, Docker (including Docker Compose) must be installed on your computer. You can find installation instructions for this in the [Docker Documentation](https://docs.docker.com/get-docker/). You will also need [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) to clone this repository.

1. #### Clone the repository
   Clone this repository. You can either use a git client with a graphical interface or use git directly from the command line:

   ```bash
   $ git clone https://github.com/tactilenews/100eyes.git
   ```

2. #### Building containers
   Change to the `100eyes` directory and build the Docker containers using Docker Compose:

    ```bash
    $ cd ~/100eyes
    $ docker-compose build
    ```

3. #### Configuration
   `100eyes` is based on some services, e.g. for sending and receiving e-mails and Telegram messages. You can set sensitive information such as API keys or passwords using environment variables. To do this, it is best to copy the template provided for this purpose:

   ```bash
   $ cp .env.template .env
   ```

   Edit the new `.env` file and add API keys and other secrets there. This file `.env` is ignored by `git`.

4. #### Start container
    You can start all containers with a single command. `100eyes` can then be viewed in your browser at http://localhost:3000.

    ```bash
    $ docker-compose up
    ```

5. #### Seed database

   One user has been created to use in development, since registration is disabled. You can create your own user in the `rails console` if you want, or you can run:

   ```bash
   $ docker-compose exec app rails db:seed
   ```

  ##### Webpack Development Server

  With this command you can speed up the compilation of the assets for development purposes (e.g. for many changes to CSS files):

  ```bash
  $ docker-compose exec app bin/webpack-dev-server
  ```

### Production
`100eyes` is a relatively simple Ruby on Rails (RoR) application and consists of the application server and a background worker to receive incoming Telegram messages.

* Ruby 2.7 (and the bundler gem)
* PostgreSQL (Version 12+)
* nginx or another reverse proxy

## Funding
The [Medieninnovationszentrum Babelsberg](http://miz-babelsberg.de) supports the development of additional modules.

## License
`100eyes` is developed by [tactile.news](https://tactile.news) and is licensed under the [MIT license](https://github.com/tactilenews/100eyes/blob/master/LICENSE).
The development of `100eyes` was funded by the [Prototype Fund](https://prototypefund.de) from the [Bundesministerium für Bildung und Forschung](https://bmbf.de).
