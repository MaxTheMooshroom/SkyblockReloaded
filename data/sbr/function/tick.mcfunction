
execute as @a unless score @s joined matches 1.. run function sbr:move_player_to_spawn
execute as @a unless score @s inventory matches 1.. run function sbr:give_starting_inventory
