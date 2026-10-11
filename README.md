# DevTools Course Glossary – Drupal Site on Docker

Final project for the **DevTools** course, Summer Semester 2026 (תשפ"ו).  
Lecturer: Mr. Lior Rotberg

---

## a. Who We Are

| Name | GitHub | Role |
|---|---|---|
| Nikita Kaltia | `<github-username>` | Team leader |
| Beni Zargarov | `<github-username>` | Team member |

We are students in the DevTools course, working together as a team of two.

---

## b. What We Were Asked To Do

The assignment was to build a **Drupal website** containing the terms from the course glossary, running entirely on **Docker**, and to make it fully reproducible on any Linux machine.

The requirements were:

1. **Docker infrastructure** – run two containers on a shared Docker network:
   - a database (PostgreSQL or MySQL, latest image), exposing its default port, with the root password `my-secret-pw`
   - Drupal (latest image), exposed on port `8080`
2. **Drupal configuration** – connect Drupal to the database by container name, set the site name to "האתר של ..." with all team members' names, create an admin account (`demoadmin` / `secretpass`) and a user account for each team member.
3. **Content** – add terms from the course glossary (available on Moodle) to the site.
4. **Backup** – back up the database (and any relevant volume files).
5. **Restore** – restore the backup on a different Linux machine and verify that the site comes back intact.
6. **Cleanup** – remove all containers, images and volumes.
7. **Automation** – write four Bash scripts: `setup.sh`, `backup.sh`, `restore.sh` and `cleanup.sh`.
8. **Git** – keep everything (scripts, configuration, backups, this README and LLM chat logs) in a shared GitHub repository, with gradual commits from every team member.

---

## c. What We Did

### Docker environment
- Wrote a **`docker-compose.yml`** that defines the entire environment in one file, instead of separate `docker run` commands:
  - **`drupal-db`** – PostgreSQL (`postgres:latest`), port `5432:5432`, user `root`, password `my-secret-pw`, database `drupal`
  - **`drupal-site`** – Drupal (`drupal:latest`), port `8080:80`, starts after the database (`depends_on`)
  - **`drupal-net`** – a shared network, so Drupal can reach the database by its container name
  - **Two named volumes** that keep data even if the containers are deleted:
    - `drupal-db-data` → `/var/lib/postgresql` (database data)
    - `drupal-sites-data` → `/var/www/html/sites` (`settings.php` and uploaded files)

### Drupal site
- Installed Drupal 11 through the web installer with the **Standard** profile, connected to PostgreSQL using the host `drupal-db`.
- Site name: **האתר של ניקיטה קלטיה ובני זרגרוב**
- Created the admin account `demoadmin` and a personal account for each team member.
- Created a custom content type, **Glossary Term**, with:
  - **Term** – the term's name (the title field)
  - **Definition** – a required, formatted long-text field
- Glossary terms are published and promoted to the front page, so they all appear on the home page.
- Both team members added terms using their own accounts, so each term shows its author.

### Scripts
- **`setup.sh`** – checks that Docker and Docker Compose are installed and running, pulls the latest images, starts the environment with Docker Compose, and waits until the database is ready.
- **`backup.sh`** – creates two backup files in the `backups/` folder:
  - `drupal_db_backup.sql` – a full PostgreSQL dump (made with `pg_dump` inside the container)
  - `drupal_sites_backup.tar.gz` – the Drupal `sites` folder, including `settings.php`, which Drupal needs to find its database after a restore
<!-- TODO (Beni): add a short description of restore.sh and cleanup.sh here once they're written. -->

### Repository structure
```
.
├── docker-compose.yml     # Defines containers, network and volumes
├── setup.sh               # Sets up the Docker environment
├── backup.sh              # Backs up the database and site files
├── restore.sh             # Restores the site from the backups
├── cleanup.sh             # Removes everything the project created
├── backups/
│   ├── drupal_db_backup.sql
│   └── drupal_sites_backup.tar.gz
├── chats/                 # LLM conversations used during the project
├── .gitignore
└── README.md
```

---

## d. Technologies We Used

| Technology | Purpose |
|---|---|
| **Docker** | Runs the database and Drupal in isolated containers |
| **Docker Compose** | Defines and starts the whole environment (containers, network, volumes) with one command |
| **PostgreSQL** (latest) | Database that stores all of the site's content, users and settings |
| **Drupal 11** (latest) | PHP-based content management system (CMS) for the website |
| **Bash** | Automation scripts for setup, backup, restore and cleanup |
| **pg_dump / psql** | PostgreSQL tools for backing up and restoring the database |
| **tar / gzip** | Packing and compressing the Drupal site files |
| **Git & GitHub** | Version control, collaboration and storing the backups |
| **macOS / Linux** | Development and testing environments |
| **Claude (LLM)** | Assistance with configuration, scripts and explanations (see `chats/`) |

---

## e. Step-by-Step Restore Guide

<!--
  TODO (Beni): write this section after you've written restore.sh and cleanup.sh
  and have actually restored the site on your machine. Follow the exact steps
  you took, so a beginner can copy them one by one.

  It should cover, in this order:

  0. Prerequisites – what must be installed (Docker + Docker Compose, Git)
     and that Docker must be running.

  1. Clone the repository:
       git clone <repo-url>
       cd <repo-folder>

  2. Make the scripts executable (once):
       chmod +x setup.sh backup.sh restore.sh cleanup.sh

  3. Run ./setup.sh – what it does, and what the user should see at the end.

  4. Run ./restore.sh – what it does (DB + site files + Drupal restart).
     IMPORTANT: tell the user NOT to open localhost:8080 and run the
     installer before restoring.

  5. Open http://localhost:8080 – what they should see (site name, terms
     on the home page).

  6. Log in as demoadmin / secretpass and check that the username appears
     at the top, the content is there, and the team members' users exist.

  7. (Optional) Make changes and run ./backup.sh to save them, then commit
     and push the backups/ folder.

  8. Run ./cleanup.sh – what it removes (containers, images, volumes,
     network) and how to verify the machine is clean, e.g.:
       docker ps -a
       docker images
       docker volume ls
       docker network ls

  Tip: add a screenshot or the expected terminal output for the main steps.
-->

---

## f. Additional Information

<!--
  TODO (Beni): add anything that helps users understand the project. Ideas:

  - Login details table:
      Admin:      demoadmin / secretpass
      DB:         host drupal-db, port 5432, user root,
                  password my-secret-pw, database drupal

  - Why we back up TWO files: the .sql has the content; the .tar.gz has
    settings.php, which tells Drupal how to reach the database. Without it,
    Drupal shows the installer again even though the DB is restored.

  - Troubleshooting:
      * "Port 8080 / 5432 is already in use" -> stop whatever is using it
        (another container or a local Postgres) and run setup.sh again.
      * Drupal shows the installer after a restore -> settings.php wasn't
        restored; run ./restore.sh again.
      * "Docker is not running" -> start Docker / Docker Desktop.

  - Security note: settings.php and the DB dump contain passwords and a
    secret key. That's acceptable for a course project, but a real site
    should never store these in a public repository.

  - Teamwork note: each team member has their own local database, and
    backups are full snapshots that can't be merged. Only one person
    edits the site at a time: pull + restore -> edit -> backup + push.

  - LLM usage: our conversations with Claude are in the chats/ folder.
-->
