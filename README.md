# heroku-bill-analyzer

Simple scraper used to create a CSV of heroku bill data across multiple apps and teams.

## Setup
```bash
bundle install
brew cask install chromedriver
cp .env.example .env
# put your secrets in .env file
```

## Usage
```bash
ruby scrape.rb -t network >results.tsv
```
