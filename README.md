# DevTools Course Glossary – Drupal Site on Docker

Final project for the **DevTools** course, Summer Semester 2026 (תשפ"ו).  
Lecturer: Mr. Lior Rotberg

---

## a. Who We Are

| Name | GitHub | Role |
|---|---|---|
| Nikita Kaltia | `NKaltia (NegativeOne36)` | Team leader |
| Beni Zargarov | `BeniZargarov` | Team member |

We are students in the DevTools course, working together as a team of two.

> Note: some of Nikita's commits appear in the history under his old Git name, **NegativeOne36**.

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
- **`restore.sh`** – pulls the latest backup from Git, loads the database and site files from `backups/` back into the containers and restarts Drupal (runs `setup.sh` first if the containers aren't running).
- **`cleanup.sh`** – deletes all the project's containers, network, volumes and images (the `backups/` folder is kept).

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

## e. Step-by-Step Setup Guide

There are two ways to get the site running:
- **Part 1 – Restore our site (recommended):** brings back our finished site from the backup in a few minutes.
- **Part 2 – Build the site from scratch:** the full process we went through ourselves, from an empty Drupal to a site with content.

### Part 1 – Restore our site from the backup

  0. Prerequisites – in order for the project to work the following must be installed:
     - **Git** - https://git-scm.com/downloads
     - **Docker + Docker Compose** - https://docs.docker.com/get-docker/
     - **Note:** docker must be open while the program works.
     
  1. Clone the repository:
       git clone https://github.com/NKaltia/NikitaKaltia_BeniZargarov_FinalProject.git
       cd NikitaKaltia_BeniZargarov_FinalProject
       
  2. Run ./setup.sh – This creates fresh, empty containers for the website and the database, without the saved data.

  3. Run ./restore.sh – This loads the saved data from the backups/ folder into the containers, so the website comes back with all its content.

  4. Open http://localhost:8080 – You should see the site **האתר של ניקיטה קלטיה ובני זרגרוב**, with the glossary terms on the home page.

  5. (Optional) Log in as demoadmin / secretpass and check that the username appears
     at the top, the content is there, and the team members' users exist.

  6. (Optional) Make changes and run ./backup.sh to save them, then commit
     and push the backups/ folder.

  7. When Closing: Run ./cleanup.sh – This deletes the containers, the network, the volumes and the images.
     Your `backups/` folder is kept, so you can always restore the site again with `./setup.sh` and `./restore.sh`

### Part 2 – Build the site from scratch (what we did)

  1. Clone the repository and run ./setup.sh (same as steps 0–2 above). Do NOT run ./restore.sh.

  2. Check that both containers are running:
       docker ps
     You should see drupal-db and drupal-site with status "Up".

  3. Open http://localhost:8080 – the Drupal installer appears.

  4. Choose language: English (Hebrew is also allowed) -> Save and continue.

  5. Choose profile: Standard -> Save and continue.

  6. Database configuration:
     - Database type:  PostgreSQL
     - Database name:  drupal
     - Username:       root
     - Password:       my-secret-pw
     - Under "Advanced options":
       - Host: drupal-db  (the container name – NOT localhost)
       - Port: 5432
     -> Save and continue, and wait for the installation to finish.

  7. Configure site:
     - Site name: האתר של ניקיטה קלטיה ובני זרגרוב
     - Site email: any email address
     - Username: demoadmin, Password: secretpass
     -> Save and continue. You are now logged in as demoadmin.

  8. Create a user for each team member:
     People -> Add user -> fill in username, email and password -> Create new account.

  9. Create the "Glossary Term" content type:
     - Structure -> Content types -> Add content type
     - Name: Glossary Term, Title field label: Term
     - Publishing options: check "Published" and "Promoted to front page"
     - Save and manage fields -> Create a new field:
       Text (formatted, long), label "Definition", mark it as Required -> Save.

  10. Add the terms: log in with your personal user,
      Content -> Add content -> Glossary Term -> enter the term and its definition
      from the course glossary on Moodle -> Save. Repeat for every term.

  11. (Optional) Change the look: Appearance -> Olivero -> Settings ->
      choose an "Olivero Color Scheme" -> Save configuration.

  12. Save your work: run ./backup.sh, then commit and push the backups/ folder:
       git add backups/
       git commit -m "Update backup"
       git push

  13. When done: run ./cleanup.sh to remove everything from the machine.

---

## f. Additional Information

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
