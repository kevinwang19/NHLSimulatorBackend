# README

Setup:

* Install Homebrew: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

* Install Ruby: brew install rbenv

* Configure Ruby:
    rbenv install 3.3.1
    rbenv global 3.3.1

* Install PostgreSQL: brew install postgresql
  
* Start PostgreSQL: brew services start postgresql

* Install Python: https://www.python.org/ftp/python/3.12.3/python-3.12.3-macos11.pkg
  
* Install Python Dependencies:
    pip3 install pandas
    pip3 install scikit-learn

* Install Bundler: gem install bundler
  
* Setup Environment Variables:
    open ~/.zshrc
        export PATH="/usr/local/opt/ruby/bin:$PATH"
        export GEM_HOME=$HOME/gems
        export PATH=$HOME/gems/bin:$PATH
        alias python=/usr/bin/python3

* Run Server: rails server
  
* Fetch initial schedules, teams, players, stats, ratings, lineups: rails app:fetch_initial
  
* Fetch updated players, stats, ratings, and lineups: rails app:fetch_update 
