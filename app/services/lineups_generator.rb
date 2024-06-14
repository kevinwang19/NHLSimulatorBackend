class LineupsGenerator
    # Save team lineups data to database
    def save_lineups_data(team_id, players)
        # Get current team players from the lineups database
        current_team_players_ids = Lineup.where(teamID: team_id).pluck(:playerID)
        updated_team_players_ids = []
        
        # Sort forwards by offensive and defensive ratings
        forwards = players.select { |player| ["C", "L", "R"].include?(player.positionCode) }
        offensive_forwards_order = forwards.sort_by { |forward| -forward["offensiveRating"] }
        defensive_forwards_order = forwards.sort_by { |forward| -forward["defensiveRating"] }
        valid_forwards = forwards.select { |forward| forward["offensiveRating"] + forward["defensiveRating"] != 0 }
        overall_forwards_order = valid_forwards.sort_by { |forward| -(forward["offensiveRating"] + forward["defensiveRating"]) }

        # Sort defensemen by offensive and defensive ratings
        defensemen = players.select { |player| player.positionCode == "D" }
        offensive_defensemen_order = defensemen.sort_by { |defenseman| -defenseman["offensiveRating"] }
        defensive_defensemen_order = defensemen.sort_by { |defenseman| -defenseman["defensiveRating"] }
        valid_defensemen = defensemen.select { |defenseman| defenseman["offensiveRating"] + defenseman["defensiveRating"] != 0 }
        overall_defensemen_order = valid_defensemen.sort_by { |defenseman| -(defenseman["offensiveRating"] + defenseman["defensiveRating"]) }

        # Sort goalies by defensive rating
        goalies = players.select { |player| player.positionCode == "G" }
        valid_goalies = goalies.select { |goalie| goalie["defensiveRating"] != 0 }
        goalies_order = valid_goalies.sort_by { |goalie| -goalie["defensiveRating"] }
       
        # Create lines based on top overall forwards and defensemen (3 forwards and 2 defensemen on each line)
        lineup1 = overall_forwards_order[0..2] + overall_defensemen_order[0..1] + [goalies_order[0]]
        lineup2 = overall_forwards_order[3..5] + overall_defensemen_order[2..3] + [goalies_order[1]]
        lineup3 = overall_forwards_order[6..8] + overall_defensemen_order[4..5]
        lineup4 = overall_forwards_order[9..11]

        # Add remaining players to extra
        extra_forwards = overall_forwards_order[12..-1] != nil ? overall_forwards_order[12..-1] : []
        extra_defensemen = overall_defensemen_order[6..-1] != nil ? overall_defensemen_order[6..-1] : []
        extra_goalies = goalies_order[2..-1] != nil ? goalies_order[2..-1] : []
        extra = extra_forwards + extra_defensemen + extra_goalies

        # Create powerplay lines based on top offensive forwards and defensemen (4 forwards and 1 defenseman on each line)
        powerplay_lineup1 = offensive_forwards_order[0..3] + [offensive_defensemen_order[0]]
        powerplay_lineup2 = offensive_forwards_order[4..7] + [offensive_defensemen_order[1]]

        # Create penalty kill lines based on top defensive forwards and defensemen (2 forwards and 2 defensemen on each line)
        penalty_kill_lineup1 = defensive_forwards_order[0..1] + defensive_defensemen_order[0..1]
        penalty_kill_lineup2 = defensive_forwards_order[2..3] + defensive_defensemen_order[2..3]

        # Create overtime lines based on top overall forwards and defensemen (2 forwards and 1 defenseman on each line)
        ot_lineup1 = overall_forwards_order[0..1] + [overall_defensemen_order[0]]
        ot_lineup2 = overall_forwards_order[2..3] + [overall_defensemen_order[1]]

        # All special lineups
        special_lineups = {
            pp1: powerplay_lineup1,
            pp2: powerplay_lineup2,
            pk1: penalty_kill_lineup1,
            pk2: penalty_kill_lineup2,
            ot1: ot_lineup1,
            ot2: ot_lineup2
        }

        # Add each line to lineups database
        save_line(team_id, 1, lineup1, special_lineups, updated_team_players_ids)
        save_line(team_id, 2, lineup2, special_lineups, updated_team_players_ids)
        save_line(team_id, 3, lineup3, special_lineups, updated_team_players_ids)
        save_line(team_id, 4, lineup4, special_lineups, updated_team_players_ids)
        save_line(team_id, nil, extra, special_lineups, updated_team_players_ids)

        # Set current team players' teamID and lines to nil if they are no longer on the team using playerID
        different_team_players_ids = current_team_players_ids - updated_team_players_ids
        unless different_team_players_ids.empty?
            Player.where(playerID: different_team_players_ids).update_all(
                teamID: nil, 
                lineNumber: nil, 
                powerPlayLineNumber: nil, 
                penaltyKillLineNumber: nil, 
                otLineNumber: nil
            )
        end
    end

    # Save specific team line to database
    def save_line(team_id, line_number, line, special_lines, updated_team_players_ids)
        # Line position counter to prevent players from being added to the same position
        position_counters = {
            "LW" => 0,
            "C" => 0,
            "RW" => 0,
            "LD" => 0,
            "RD" => 0
        }

        # Add each player lineup stat from the line to the Lineup table
        line.each do |player|
            # Add new lineup data to the updated team players list
            updated_team_players_ids << player.playerID

            # Get player position and check if player is on any special lines
            position = position(player.positionCode, player.shootsCatches, position_counters)
            powerPlayLineNumber = special_lines[:pp1].include?(player) ? 1 : (special_lines[:pp2].include?(player) ? 2 : nil)
            penaltyKillLineNumber = special_lines[:pk1].include?(player) ? 1 : (special_lines[:pk2].include?(player) ? 2 : nil)
            otLineNumber = special_lines[:ot1].include?(player) ? 1 : (special_lines[:ot2].include?(player) ? 2 : nil)
            
            # Find if the player already exists in the database
            existing_player = Lineup.find_by(playerID: player.playerID)

            # Update required attributes if the player exists, otherwise add the player to the database
            if existing_player
                existing_player.update(
                    teamID: team_id,
                    position: position,
                    lineNumber: line_number,
                    powerPlayLineNumber: powerPlayLineNumber,
                    penaltyKillLineNumber: penaltyKillLineNumber,
                    otLineNumber: otLineNumber
                )
            else
                Lineup.create(
                    playerID: player.playerID,
                    teamID: team_id,
                    position: position,
                    lineNumber: line_number,
                    powerPlayLineNumber: powerPlayLineNumber,
                    penaltyKillLineNumber: penaltyKillLineNumber,
                    otLineNumber: otLineNumber
                )
            end
        end
    end

    # Assign unique position for each player on the line
    def position(position_code, shoot_handness, position_counters)
        # Add players in most desired position based on the order and based on their handness

        if position_code == "G"
            return "G"
        elsif position_code == "D"
            # 1. Place defensemen in LD if he shoots left and the left defense position is open
            if shoot_handness == "L" && position_counters["LD"] == 0
                position_counters["LD"] += 1
                return "LD"
            # 2. Place defensemen in RD if he shoots right and the right defense position is open
            elsif shoot_handness == "R" && position_counters["RD"] == 0
                position_counters["RD"] += 1
                return "RD"
            # 3. Place defensemen in LD if he shoots right but the right defense position is taken
            elsif shoot_handness == "R" && position_counters["LD"] == 0
                position_counters["LD"] += 1
                return "LD"
            # 4. Place defensemen in RD if he shoots left but the left defense position is taken
            else 
                position_counters["RD"] += 1
                return "RD"
            end
        else
            # 1. Place forward in C if he is a centerman and the center position is open
            if position_code == "C" && position_counters["C"] == 0
                position_counters["C"] += 1
                return "C"
            # 2. Place forward in LW if he is a left winger and the left wing position is open
            elsif position_code == "L" && position_counters["LW"] == 0
                position_counters["LW"] += 1
                return "LW"
            # 3. Place forward in RW if he is a right winger and the right wing position is open
            elsif position_code == "R" && position_counters["RW"] == 0
                position_counters["RW"] += 1
                return "RW"
            # 4. Place forward in LW if he is a centerman and shoots left but the center position is taken
            elsif position_code == "C" && shoot_handness == "L" && position_counters["LW"] == 0
                position_counters["LW"] += 1
                return "LW"
            # 5. Place forward in RW if he is a centerman and shoots right but the center position is taken
            elsif position_code == "C" && shoot_handness == "R" && position_counters["RW"] == 0
                position_counters["RW"] += 1
                return "RW"
            # 6. Place forward in LW if he is a centerman and shoots right but the center and right wing position are taken
            elsif position_code == "C" && position_counters["LW"] == 0
                position_counters["LW"] += 1
                return "LW"
            # 6. Place forward in RW if he is a centerman and shoots left but the center and left wing position are taken
            elsif position_code == "C" && position_counters["RW"] == 0
                position_counters["RW"] += 1
                return "RW"
            # 7. Place forward in RW if he is a left winger but the left wing position is taken
            elsif position_code== "L" && position_counters["RW"] == 0
                position_counters["RW"] += 1
                return "RW"
            # 8. Place forward in LW if he is a right winger but the right wing position is taken
            elsif position_code == "R" && position_counters["LW"] == 0
                position_counters["LW"] += 1
                return "LW"
            # 9. Place forward in C if he is a winger and both wing positions are taken
            else
                position_counters["C"] += 1
                return "C"
            end
        end
    end
end