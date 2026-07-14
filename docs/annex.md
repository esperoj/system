# Perma-Store: Sovereign Binary Vault

An offline-first, text-verifiable binary payload storage repository using `git-annex`. This repository serves exclusively as the physical storage layer for the Perma project. It focuses on structural simplicity, cryptographic integrity verification, and explicit separation of concerns from the logical metadata database.

---

## 1. Architectural Philosophy & Separation of Concerns

This system separates metadata meaning from physical byte storage:

* **Logical Layer (Django Admin & SQLite):** Manages the human aspect of preservation—authors, context, relationships, notes, and file path mappings.
* **Physical Layer (`perma-store`):** Manages the raw files on disk (`store/`), physical locations across backup media, and data integrity verification.

```
+------------------------------------+       +------------------------------------+
|            LOGICAL LAYER           |       |           PHYSICAL LAYER           |
|            (Perma Django)          |       |           (perma-store)            |
|                                    |       |                                    |
| * Author, Notes, Relationships     |       | * Raw Binaries (/store/)           |
| * Path Mapping (store/texts/...)   | <===> | * git-annex Location Tracking      |
| * SQLite Database Engine           |       | * Cryptographic Integrity (fsck)   |
+------------------------------------+       +------------------------------------+

```

---

## 2. Vault Layout (`master` branch)

The workspace uses a single **`store/`** directory organized by primary media types mirrored after the Internet Archive taxonomy. Within these top-level divisions, assets are grouped into distinct sub-categories, with an `others/` directory inside each main media type to catch miscellaneous items. Filenames omit special characters and use underscores to optimize parsing and cross-platform compatibility.

```text
perma-store/
├── .git/
├── .gitattributes      # Instructs Git to annex all files under store/
└── store/
    ├── texts/          # Monograph materials, articles, and print media
    │   ├── books/
    │   │   └── Le_Guin_Ursula_The_Dispossessed/
    │   │       ├── Le_Guin_Ursula_The_Dispossessed.epub
    │   │       └── Le_Guin_Ursula_The_Dispossessed.pdf
    │   └── others/
    ├── audio/          # Music, podcasts, spoken word, and soundscapes
    │   ├── music/
    │   │   └── Pink_Floyd_Dark_Side_Of_The_Moon/
    │   │       └── 01_Breathe.flac
    │   └── others/
    ├── images/         # Stills, photographs, artwork, and visual scans
    │   ├── posters/
    │   │   └── Retro_SciFi_Art_01.jpg
    │   └── others/
    ├── videos/         # Moving image assets, films, and animations
    │   ├── anime/
    │   │   └── Series_Title_Episode_01.mkv
    │   └── others/
    ├── software/       # Operating systems, utilities, tools, and emulated ROMs
    │   ├── systems/
    │   │   └── Debian_12_NetInst.iso
    │   └── others/
    └── data/           # Datasets, scientific files, and structural dumps
        ├── catalog_exports/
        │   └── backup_dump.sql
        └── others/

```

### `.gitattributes` Configuration

To ensure comprehensive tracking across the entire storage pool, everything residing under the `store/` prefix is systematically routed to git-annex, allowing files of any extension (including Markdown documentation or plain-text notes) to be annexed:

```text
# Force absolutely everything under the store folder into git-annex
store/** filter=annex diff=annex merge=annex

```

---

## 3. Initialization & Local Setup

Initialize the dedicated storage pool as a pure, independent git-annex node.

```bash
# Create and enter the vault directory
mkdir -p ~/projects/perma-store
cd ~/projects/perma-store

# Initialize Git and git-annex
git init
git annex init "local-vault"

# Configure standard annex options
git config annex.genmetadata false

```

---

## 4. Ingestion & Sync Pipelines

### Pipeline A: Ingesting New Local Media

Use this manual process when physical files are introduced to the storage layout before registering them in Django.

```bash
# 1. Create the specific sub-category item directory if it doesn't exist
mkdir -p store/texts/books/Quantum_Mechanics_Intro/

# 2. Place the binary assets into the appropriate path
mv ~/Downloads/Quantum_Mechanics_Intro.pdf store/texts/books/Quantum_Mechanics_Intro/

# 3. Ingest the file into git-annex tracking
git annex add store/texts/books/Quantum_Mechanics_Intro/

# 4. Commit the structural pointer to Git
git commit -m "Ingest: store/texts/books/Quantum_Mechanics_Intro/"

# 5. (Next Step) Copy the relative path structure and paste it into the 
#    Django Admin interface alongside Author and Note details.

```

### Pipeline B: Direct Network Ingestion (Web Archiving)

Use this method to retrieve remote assets directly into the `store/` tree while simultaneously preserving the verifiable source URL.

```bash
# 1. Download and track directly into the targeted media hierarchy
git annex addurl "https://example.com/files/mechanics.pdf" --file store/texts/books/Quantum_Mechanics_Intro/Quantum_Mechanics_Intro.pdf

# 2. Commit the tracking pointer
git commit -m "Web Ingest: store/texts/books/Quantum_Mechanics_Intro/Quantum_Mechanics_Intro.pdf"

```

---

## 5. Maintenance, Auditing & Safeguards

### Automated Integrity Checks (`fsck`)

To combat silent bit rot on disk, run background validation passes routinely. The following command limits execution windows to prevent resource starvation, processes data concurrently, and checks incremental blocks over 30-day windows:

```bash
git annex fsck --incremental-schedule 30d --time-limit 30m --jobs 4

```

### Verifying Web Archive Backends

When assets are sourced or backed up via online archives (such as the Wayback Machine), validate the remote availability of those target URLs directly:

```bash
git annex fsck --from=web --url='*://web.archive.org*' --incremental-schedule 30d --time-limit 30m --jobs 4

```

### Handling Moves and Renames

Because Django references files by their location string, if you rearrange items inside `store/`, remember to re-index the files and update the Django catalog database:

```bash
# Update the local git tracking tree after moving a file or directory
git annex add store/new_media_type/sub_category/item_directory/
git commit -m "Relocate: updated media tree layout"

```
