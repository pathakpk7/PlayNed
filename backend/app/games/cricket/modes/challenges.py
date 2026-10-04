import random
from typing import Dict, Any, List, Optional
from backend.app.games.cricket.data.players import CRICKET_PLAYERS_DATA, get_all_cricket_players, get_cricket_player_by_id

class CricketChallengeEngine:
    """
    Cricket Challenge Hub mini-games engine:
    1. Who Am I? (Progressive clues, guess player)
    2. Higher or Lower? (Compare stat between two players)
    3. Stat or Fiction? (True/False trivia statements)
    4. Career Timeline? (Chronological ordering of players / milestones)
    5. Guess the Player? (Multiple choice from clues)
    """

    STAT_FICTION_QUESTIONS = [
        {
            "id": "sf_1",
            "statement": "Rohit Sharma is the only batter in cricket history with 3 double centuries in Men's ODIs.",
            "is_true": True,
            "explanation": "Rohit scored 209 vs Australia (2013), 264 vs Sri Lanka (2014), and 208* vs Sri Lanka (2017)."
        },
        {
            "id": "sf_2",
            "statement": "Muttiah Muralitharan took exactly 750 wickets in Test Cricket.",
            "is_true": False,
            "explanation": "Muttiah Muralitharan is the all-time leading wicket-taker in Tests with 800 wickets (67 five-wicket hauls)."
        },
        {
            "id": "sf_3",
            "statement": "Virat Kohli scored 50 ODI centuries, breaking Sachin Tendulkar's long-standing record of 49.",
            "is_true": True,
            "explanation": "Virat Kohli reached his 50th ODI century at the 2023 ICC World Cup semi-final at Wankhede Stadium."
        },
        {
            "id": "sf_4",
            "statement": "Chris Gayle hit the fastest century in T20 cricket history off just 30 balls.",
            "is_true": True,
            "explanation": "Gayle smashed 175* off 66 balls in IPL 2013 for RCB vs PWI, reaching 100 in 30 balls."
        },
        {
            "id": "sf_5",
            "statement": "Shane Warne scored 3 Test centuries during his legendary international career.",
            "is_true": False,
            "explanation": "Shane Warne holds the record for the most Test runs (3,154) without ever scoring a century (highest score 99)."
        },
        {
            "id": "sf_6",
            "statement": "AB de Villiers scored the fastest ODI century in history in just 31 balls.",
            "is_true": True,
            "explanation": "AB de Villiers smashed a 31-ball ton against the West Indies in Johannesburg in January 2015."
        },
        {
            "id": "sf_7",
            "statement": "Wasim Akram took over 500 ODI wickets during his international career.",
            "is_true": True,
            "explanation": "Wasim Akram was the first bowler to reach 500 ODI wickets, finishing with 502."
        },
        {
            "id": "sf_8",
            "statement": "Sachin Tendulkar scored exactly 99 international centuries across Test and ODI cricket.",
            "is_true": False,
            "explanation": "Sachin Tendulkar is the only player in history to score 100 international centuries (51 Tests + 49 ODIs)."
        },
        {
            "id": "sf_9",
            "statement": "MS Dhoni hit a six to finish and win the 2011 ICC Cricket World Cup for India.",
            "is_true": True,
            "explanation": "Dhoni hit Nuwan Kulasekara over long-on for six to seal the 2011 World Cup at Wankhede."
        },
        {
            "id": "sf_10",
            "statement": "Lasith Malinga is the only bowler to take 4 wickets in 4 consecutive balls twice in international cricket.",
            "is_true": True,
            "explanation": "Malinga achieved 4 in 4 against South Africa (2007 World Cup) and New Zealand (2019 T20I)."
        },
        {
            "id": "sf_11",
            "statement": "Jacques Kallis scored over 10,000 runs and took over 250 wickets in both Tests and ODIs.",
            "is_true": True,
            "explanation": "Kallis is the only all-rounder in history to achieve the 10,000 run / 250 wicket double in both formats."
        },
        {
            "id": "sf_12",
            "statement": "Brian Lara's 400 not out against England is the second-highest individual score in Test history.",
            "is_true": False,
            "explanation": "Brian Lara's 400* at Antigua in 2004 is the highest individual score in Test cricket history."
        },
        {
            "id": "sf_13",
            "statement": "Yuvraj Singh hit 6 sixes in an over off Stuart Broad in the 2007 ICC T20 World Cup.",
            "is_true": True,
            "explanation": "Yuvraj achieved the feat in Durban in September 2007, reaching a 12-ball fifty."
        },
        {
            "id": "sf_14",
            "statement": "Glenn McGrath holds the all-time record for the most wickets in ICC Cricket World Cup history.",
            "is_true": True,
            "explanation": "Glenn McGrath captured 71 wickets in 39 matches across 4 World Cup tournaments."
        },
        {
            "id": "sf_15",
            "statement": "Jim Laker and Anil Kumble are the only two bowlers to take all 10 wickets in a Test innings.",
            "is_true": False,
            "explanation": "Ajaz Patel of New Zealand also took all 10 wickets in a Test innings vs India in Mumbai in 2021 (3 bowlers total)."
        },
        {
            "id": "sf_16",
            "statement": "Shoaib Akhtar delivered the fastest officially recorded ball in cricket history at 161.3 km/h (100.2 mph).",
            "is_true": True,
            "explanation": "Bowled against England during the 2003 World Cup in South Africa to Nick Knight."
        },
        {
            "id": "sf_17",
            "statement": "Ricky Ponting captained Australia to undefeated ICC World Cup titles in both 2003 and 2007.",
            "is_true": True,
            "explanation": "Australia went undefeated through both tournaments under Ponting's legendary leadership."
        },
        {
            "id": "sf_18",
            "statement": "Don Bradman finished his Test career with a perfect batting average of 100.00.",
            "is_true": False,
            "explanation": "Bradman was bowled for a duck in his final Test innings at The Oval in 1948 and finished with 99.94."
        },
        {
            "id": "sf_19",
            "statement": "Jasprit Bumrah holds the world record for the most runs scored off a single over in Test cricket.",
            "is_true": True,
            "explanation": "Bumrah smashed Stuart Broad for 29 runs off the bat (35 runs total in the over) at Edgbaston in 2022."
        },
        {
            "id": "sf_20",
            "statement": "Sanath Jayasuriya took more ODI wickets in his career than Shane Warne.",
            "is_true": True,
            "explanation": "Jayasuriya took 323 ODI wickets with his left-arm spin, whereas Warne took 293 ODI wickets."
        },
        {
            "id": "sf_21",
            "statement": "Ben Stokes was awarded Player of the Match in the 2019 ICC Cricket World Cup Final.",
            "is_true": True,
            "explanation": "Stokes scored 84* in regulation and batted in the Super Over to win the title for England."
        },
        {
            "id": "sf_22",
            "statement": "Kumar Sangakkara scored 4 consecutive centuries in a single ICC World Cup edition.",
            "is_true": True,
            "explanation": "Achieved at the 2015 World Cup vs Bangladesh, England, Australia, and Scotland."
        },
        {
            "id": "sf_23",
            "statement": "Dale Steyn was ranked the ICC No. 1 Test bowler in the world for over 5 consecutive years.",
            "is_true": True,
            "explanation": "Steyn held the World No. 1 ranking for a record 263 weeks between 2008 and 2014."
        },
        {
            "id": "sf_24",
            "statement": "Shahid Afridi scored his fastest 37-ball ODI century using a bat given by Sachin Tendulkar.",
            "is_true": True,
            "explanation": "Afridi borrowed Waqar Younis's kit bag which held a spare bat given by Sachin Tendulkar."
        },
        {
            "id": "sf_25",
            "statement": "James Anderson is the first and only fast bowler in cricket history to take 700 Test wickets.",
            "is_true": True,
            "explanation": "Anderson finished with 704 Test wickets across 188 matches for England."
        },
        {
            "id": "sf_26",
            "statement": "Sunil Gavaskar was the first cricketer in history to reach 10,000 Test runs.",
            "is_true": True,
            "explanation": "Gavaskar crossed 10,000 Test runs in March 1987 in Ahmedabad against Pakistan."
        },
        {
            "id": "sf_27",
            "statement": "Adam Gilchrist batted with a squash ball inside his batting glove in the 2007 World Cup Final.",
            "is_true": True,
            "explanation": "Gilchrist smashed 149 off 104 balls using a squash ball for a firmer top-hand grip."
        },
        {
            "id": "sf_28",
            "statement": "Brendon McCullum scored the fastest Test century in history off just 54 balls.",
            "is_true": True,
            "explanation": "Scored against Australia in his farewell Test at Christchurch in February 2016."
        },
        {
            "id": "sf_29",
            "statement": "MS Dhoni is the only captain to win the T20 World Cup, ODI World Cup, and Champions Trophy.",
            "is_true": True,
            "explanation": "Dhoni won the 2007 T20 WC, 2011 ODI WC, and 2013 ICC Champions Trophy for India."
        },
        {
            "id": "sf_30",
            "statement": "Eoin Morgan hit a world record 17 sixes in a single ODI innings during the 2019 World Cup.",
            "is_true": True,
            "explanation": "Morgan smashed 148 off 71 balls with 17 sixes against Afghanistan at Old Trafford."
        },
        {
            "id": "sf_31",
            "statement": "Mitchell Starc was the leading wicket-taker in both the 2015 and 2019 ICC World Cups.",
            "is_true": True,
            "explanation": "Starc took 22 wickets in 2015 and a tournament-record 27 wickets in 2019."
        },
        {
            "id": "sf_32",
            "statement": "Virender Sehwag and Chris Gayle are the only two cricketers with two Test 300s and an ODI 200.",
            "is_true": True,
            "explanation": "Both icons registered two triple-centuries in Tests and a double-century in ODIs."
        },
        {
            "id": "sf_33",
            "statement": "Pat Cummins took two hat-tricks in consecutive matches during the 2024 ICC T20 World Cup.",
            "is_true": True,
            "explanation": "Cummins took hat-tricks against Bangladesh and Afghanistan in the Super 8 stage."
        },
        {
            "id": "sf_34",
            "statement": "Sachin Tendulkar made his international Test debut at age 16 against Pakistan in 1989.",
            "is_true": True,
            "explanation": "Debuted in Karachi in November 1989 facing Imran Khan, Wasim Akram, and Waqar Younis."
        },
        {
            "id": "sf_35",
            "statement": "Chaminda Vaas took 8/19 in an ODI, the best bowling figures in Men's ODI history.",
            "is_true": True,
            "explanation": "Vaas took 8 wickets for 19 runs against Zimbabwe in Colombo in 2001."
        },
        {
            "id": "sf_36",
            "statement": "Muttiah Muralitharan claimed 67 five-wicket hauls in Test cricket, the most in history.",
            "is_true": True,
            "explanation": "Muralitharan took 67 five-wicket hauls, far ahead of Shane Warne in second place (37)."
        },
        {
            "id": "sf_37",
            "statement": "Courtney Walsh was the first bowler in cricket history to reach 500 Test wickets.",
            "is_true": True,
            "explanation": "The West Indian fast bowler reached 500 Test wickets in March 2001."
        },
        {
            "id": "sf_38",
            "statement": "Viv Richards scored a 56-ball Test century against England in 1986.",
            "is_true": True,
            "explanation": "The Master Blaster's 56-ball hundred in Antigua stood as the fastest Test ton for 30 years."
        },
        {
            "id": "sf_39",
            "statement": "Kapil Dev never bowled a single no-ball in his entire 16-year international career.",
            "is_true": True,
            "explanation": "Kapil Dev bowled over 4,800 overs in international cricket without overstepping the crease once."
        },
        {
            "id": "sf_40",
            "statement": "India's lowest completed innings total in Test cricket history is 36 all out.",
            "is_true": True,
            "explanation": "Occurred at the Adelaide Oval against Australia in the Day-Night Test in December 2020."
        },
        {
            "id": "sf_41",
            "statement": "Anil Kumble took 10 wickets in a single Test innings against Pakistan at Feroz Shah Kotla in 1999.",
            "is_true": True,
            "explanation": "Kumble took 10/74 in Delhi, becoming only the second bowler in Test history to take all 10 wickets in an innings."
        },
        {
            "id": "sf_42",
            "statement": "Ricky Ponting is the only cricketer to feature in over 100 Test match victories as a player.",
            "is_true": True,
            "explanation": "Ponting featured in 108 Test match victories for Australia, the most by any player in history."
        },
        {
            "id": "sf_43",
            "statement": "Rahul Dravid faced more deliveries (31,258 balls) than any batter in Test match history.",
            "is_true": True,
            "explanation": "Known as 'The Wall', Dravid batted for 44,152 minutes and faced 31,258 balls in Test cricket."
        },
        {
            "id": "sf_44",
            "statement": "Ravichandran Ashwin took 500 Test wickets in fewer matches than any other Indian bowler.",
            "is_true": True,
            "explanation": "Ashwin reached 500 Test wickets in 98 matches, second-fastest globally behind Muralitharan (87 matches)."
        },
        {
            "id": "sf_45",
            "statement": "Sourav Ganguly won 4 consecutive Man of the Match awards in ODI cricket in 1997.",
            "is_true": True,
            "explanation": "Ganguly achieved this world record against Pakistan in the 1997 Sahara Cup in Toronto."
        },
        {
            "id": "sf_46",
            "statement": "Sunil Gavaskar was dismissed off the very first ball of a Test match 3 times in his career.",
            "is_true": True,
            "explanation": "Gavaskar fell to the first ball of a Test match thrice (against Geoff Arnold, Malcolm Marshall, Imran Khan)."
        },
        {
            "id": "sf_47",
            "statement": "Zaheer Khan and Shahid Afridi were the joint-highest wicket-takers in the 2011 ICC World Cup with 21 wickets.",
            "is_true": True,
            "explanation": "Both champions topped the wicket-taking charts with 21 scalps each in 2011."
        },
        {
            "id": "sf_48",
            "statement": "Adam Gilchrist scored a century in all three ICC World Cup finals he played (1999, 2003, 2007).",
            "is_true": False,
            "explanation": "Gilchrist scored 54 in 1999, 57 in 2003, and 149 in 2007 (one century)."
        },
        {
            "id": "sf_49",
            "statement": "Glenn Maxwell scored the first double century in an ODI run chase (201* vs Afghanistan in 2023).",
            "is_true": True,
            "explanation": "Maxwell smashed 201* off 128 balls battling severe cramps to pull off a miracle chase from 91/7."
        },
        {
            "id": "sf_50",
            "statement": "Herschelle Gibbs was the first cricketer to hit 6 sixes in an over in an international match.",
            "is_true": True,
            "explanation": "Gibbs smashed Daan van Bunge of Netherlands for 6 sixes in the 2007 ODI World Cup in St. Kitts."
        },
        {
            "id": "sf_51",
            "statement": "South Africa successfully chased down a world-record 434 runs against Australia in the 2006 Johannesburg ODI.",
            "is_true": True,
            "explanation": "South Africa scored 438/9 with one ball to spare in one of the greatest matches ever played."
        },
        {
            "id": "sf_52",
            "statement": "MS Dhoni holds the highest individual score by a wicket-keeper in ODI history: 183 not out.",
            "is_true": True,
            "explanation": "Dhoni smashed 183* off 145 balls against Sri Lanka in Jaipur in October 2005."
        },
        {
            "id": "sf_53",
            "statement": "Steve Smith began his international cricket career primarily as a leg-spin bowling all-rounder.",
            "is_true": True,
            "explanation": "Smith debuted batting at No. 8 and bowling leg-spin before transforming into an all-time great batter."
        },
        {
            "id": "sf_54",
            "statement": "Brian Lara's 501 not out for Warwickshire in 1994 is the highest score in first-class cricket history.",
            "is_true": True,
            "explanation": "Lara scored 501* against Durham, the only quintuple-century in first-class cricket."
        },
        {
            "id": "sf_55",
            "statement": "Sachin Tendulkar holds the record for the most dismissals in the nineties (90s) in international cricket.",
            "is_true": True,
            "explanation": "Sachin was out in the 90s a record 28 times in international cricket (18 in ODIs, 10 in Tests)."
        },
        {
            "id": "sf_56",
            "statement": "Sanath Jayasuriya is the only player in cricket history with over 13,000 runs and 300 wickets in ODIs.",
            "is_true": True,
            "explanation": "Jayasuriya amassed 13,430 runs and 323 wickets in 445 ODIs."
        },
        {
            "id": "sf_57",
            "statement": "Shakib Al Hasan scored 600+ runs and took 10+ wickets in a single ICC World Cup tournament (2019).",
            "is_true": True,
            "explanation": "Shakib is the only cricketer in World Cup history to achieve this rare all-round double in a single edition."
        },
        {
            "id": "sf_58",
            "statement": "Allan Border was the first batter in Test cricket history to reach 11,000 career runs.",
            "is_true": True,
            "explanation": "The Australian captain reached the milestone in 1993 before retiring with 11,174 runs."
        },
        {
            "id": "sf_59",
            "statement": "Clive Lloyd captained the West Indies to back-to-back ICC World Cup victories in 1975 and 1979.",
            "is_true": True,
            "explanation": "Lloyd led the legendary West Indian side that dominated early World Cup cricket."
        },
        {
            "id": "sf_60",
            "statement": "Imran Khan led Pakistan to their first-ever ICC World Cup triumph in 1992 at age 39.",
            "is_true": True,
            "explanation": "Imran inspired his 'Cornered Tigers' to defeat England at the Melbourne Cricket Ground in 1992."
        },
        {
            "id": "sf_61",
            "statement": "Martin Guptill's 237 not out against the West Indies is the highest individual score in World Cup history.",
            "is_true": True,
            "explanation": "Guptill smashed 237* off 163 balls in the 2015 World Cup quarter-final in Wellington."
        },
        {
            "id": "sf_62",
            "statement": "Anil Kumble bowled with a broken jaw against the West Indies in Antigua in 2002.",
            "is_true": True,
            "explanation": "Kumble returned with his face bandaged and famously dismissed Brian Lara in a heroic spell."
        },
        {
            "id": "sf_63",
            "statement": "Muttiah Muralitharan claimed 9 wickets in a single Test innings on two separate occasions.",
            "is_true": True,
            "explanation": "Murali took 9/51 vs Zimbabwe (2002) and 9/65 vs England at The Oval (1998)."
        },
        {
            "id": "sf_64",
            "statement": "Rohit Sharma scored 5 centuries in a single ICC World Cup tournament (2019).",
            "is_true": True,
            "explanation": "Rohit scored centuries against South Africa, Pakistan, England, Bangladesh, and Sri Lanka in 2019."
        },
        {
            "id": "sf_65",
            "statement": "Glenn McGrath took best ODI bowling figures of 7 wickets for 15 runs in the 2003 World Cup.",
            "is_true": True,
            "explanation": "McGrath took 7/15 against Namibia in Potchefstroom in the 2003 World Cup."
        }
    ]

    WHO_AM_I_CUSTOM_CLUES = {
        "virat_kohli": [
            "I am known globally by the nickname 'King' or 'Chase Master'.",
            "I represented India and won the 2011 ODI World Cup & 2024 T20 World Cup.",
            "I hold the world record for the most centuries in ODI history (50 centuries).",
            "I scored 973 runs in a single IPL season (2016) with 4 centuries.",
            "I have amassed over 26,900 international runs across all formats."
        ],
        "sachin_tendulkar": [
            "I am revered worldwide as the 'Little Master' and 'God of Cricket'.",
            "I made my international Test debut at age 16 against Pakistan in 1989.",
            "I am the only cricketer in history to score 100 international centuries.",
            "I was the first male cricketer to score a double century in ODI history (200* vs South Africa).",
            "I finished my career with 34,357 international runs across 664 matches."
        ],
        "ms_dhoni": [
            "I am celebrated as 'Captain Cool' and 'Thala' for my composure under pressure.",
            "I famously hit the winning six to seal the 2011 ICC Cricket World Cup at Wankhede.",
            "I am the only captain in cricket history to win all three ICC white-ball trophies.",
            "I hold the record for the most stumpings in international cricket (195 stumpings).",
            "I scored 10,773 ODI runs with an average over 50 while batting largely in the lower-middle order."
        ],
        "rohit_sharma": [
            "I am widely known by the nickname 'Hitman' for my effortless power hitting.",
            "I am the only batter in cricket history to score 3 double centuries in Men's ODIs.",
            "I hold the world record for the highest individual ODI score: 264 against Sri Lanka.",
            "I led India to victory in the 2024 ICC T20 World Cup as captain.",
            "I have struck over 620 international sixes, the most in international cricket history."
        ],
        "ab_de_villiers": [
            "I earned the iconic nickname 'Mr. 360' for hitting boundaries all around the ground.",
            "I represented South Africa as an electrifying batter and wicket-keeper.",
            "I hold the world record for the fastest ODI fifty (16 balls) and fastest ODI century (31 balls).",
            "I scored 20,014 international runs with an average over 50 in both Tests and ODIs.",
            "I struck 149 off 44 balls in a famous ODI masterclass against the West Indies."
        ],
        "wasim_akram": [
            "I am universally hailed as the 'Sultan of Swing' for my mastery of reverse swing.",
            "I was named Player of the Match in the 1992 ICC Cricket World Cup Final in Melbourne.",
            "I was the first bowler in history to capture 500 ODI wickets.",
            "I took two international hat-tricks in Tests and two in ODIs.",
            "I took 916 international wickets and scored a Test double-century (257*)."
        ],
        "shane_warne": [
            "I was crowned the 'King of Spin' and bowled the 'Ball of the Century' to Mike Gatting in 1993.",
            "I led Rajasthan Royals to the inaugural IPL championship title in 2008.",
            "I took 708 Test wickets with my mesmerizing leg-spin and flippers.",
            "I was named Player of the Match in both the semi-final and final of the 1999 World Cup.",
            "I scored 3,154 Test runs with a top score of 99, the most runs without a Test century."
        ],
        "muttiah_muralitharan": [
            "I am the all-time highest wicket-taker in both Test cricket and ODI cricket history.",
            "I took a staggering 800 wickets in 133 Tests and 534 wickets in ODIs for Sri Lanka.",
            "I claimed an unmatched 67 five-wicket hauls in Test match cricket.",
            "I was a key member of Sri Lanka's 1996 ICC Cricket World Cup winning squad.",
            "I accumulated 1,347 international wickets across my illustrious 19-year career."
        ],
        "jasprit_bumrah": [
            "I am famous for my unorthodox sling-arm bowling action and pinpoint yorkers.",
            "I was named Player of the Tournament in India's triumphant 2024 ICC T20 World Cup campaign.",
            "I became the fastest Indian pacer to reach 100 Test wickets.",
            "I hold the world record for scoring 35 runs in a single Test over off Stuart Broad.",
            "I have captured over 390 international wickets across all three formats with an elite economy rate."
        ],
        "brian_lara": [
            "I am famously known as the 'Prince of Trinidad'.",
            "I hold the world record for the highest individual score in Test history (400 not out vs England).",
            "I also hold the world record for the highest first-class score: 501 not out for Warwickshire.",
            "I scored 11,953 Test runs and 10,405 ODI runs for the West Indies.",
            "I scored 28 runs in a single Test over off Robin Peterson in 2003."
        ],
        "chris_gayle": [
            "I crowned myself the 'Universe Boss' for my destructive boundary-hitting power.",
            "I scored the fastest century in T20 history off just 30 balls (175* for RCB in IPL 2013).",
            "I am one of only two players in history with two Test triple-centuries and an ODI double-century.",
            "I hit 553 international sixes and helped West Indies win two ICC T20 World Cups.",
            "I scored over 19,500 international runs across 483 matches."
        ],
        "glenn_mcgrath": [
            "I was nicknamed 'Pigeon' and known for relentless metronomic accuracy on the corridor of uncertainty.",
            "I won three consecutive ICC Cricket World Cups with Australia (1999, 2003, 2007).",
            "I hold the all-time record for the most wickets in World Cup history (71 wickets).",
            "I took 563 Test wickets and 381 ODI wickets with a career economy under 3.9.",
            "I claimed best ODI bowling figures of 7/15 against Namibia in the 2003 World Cup."
        ],
        "mitchell_starc": [
            "I am Australia's premier left-arm fast bowler known for fast, swinging yorkers.",
            "I was named Player of the Tournament at the 2015 ICC Cricket World Cup with 22 wickets.",
            "I hold the record for the most wickets in a single World Cup edition (27 wickets in 2019).",
            "I have taken over 660 international wickets across Tests, ODIs, and T20Is.",
            "I famously bowled Brendon McCullum in the first over of the 2015 World Cup Final."
        ],
        "shaheen_afridi": [
            "I am Pakistan's premier tall left-arm fast bowler known for opening-over breakthroughs.",
            "I produced a sensational 3-wicket opening spell vs India at the 2021 T20 World Cup in Dubai.",
            "I became the youngest bowler to take a 6-wicket haul in World Cup history (6/35 vs Bangladesh at Lord's).",
            "I was awarded the ICC Men's Cricketer of the Year (Sir Garfield Sobers Trophy) in 2021.",
            "I have crossed 300 international wickets with 113 in Tests and over 100 in ODIs."
        ],
        "ben_stokes": [
            "I produced two of the most miraculous fourth-innings masterclasses in 2019 at Lord's and Headingley.",
            "I hit 135* to win the Ashes Test at Headingley with a 76-run last-wicket partnership with Jack Leach.",
            "I was named Player of the Match in the dramatic 2019 ICC Cricket World Cup Final.",
            "I captained England in Test cricket under the revolutionary aggressive 'Bazball' philosophy.",
            "I have accumulated over 10,500 international runs and taken over 280 international wickets."
        ],
        "dale_steyn": [
            "I was nicknamed the 'Steyn Gun' for my searing 150 km/h outswingers and fiery vein-popping celebrations.",
            "I remained the ICC No. 1 ranked Test bowler in the world for a record 263 consecutive weeks.",
            "I captured 439 Test wickets in 93 matches with a sensational strike rate of 42.3.",
            "I took 699 international wickets for South Africa across all formats.",
            "I took 7/51 against India in Nagpur in 2010 to seal a historic Test win in subcontinental conditions."
        ],
        "ricky_ponting": [
            "I am known by the nickname 'Punter' and was renowned as the finest puller and hooker of fast bowling.",
            "I captained Australia to back-to-back undefeated ICC ODI World Cup championships in 2003 and 2007.",
            "I smashed 140 not out off 121 balls in the 2003 World Cup Final in Johannesburg.",
            "I scored 27,483 international runs with 71 international centuries (41 in Tests, 30 in ODIs).",
            "I am the most successful captain in international cricket history with 220 international wins."
        ],
        "kumar_sangakkara": [
            "I am a stylish Sri Lankan left-handed batter and wicket-keeper who scored 28,016 international runs.",
            "I scored 4 consecutive centuries in the 2015 ICC Cricket World Cup, an all-time tournament record.",
            "I scored 12,400 Test runs at an extraordinary average of 57.40 with 38 centuries and 11 double-tons.",
            "I helped Sri Lanka win the 2014 ICC World Twenty20, winning Player of the Match in the final.",
            "I share the world record for the highest partnership in Test history (624 runs with Mahela Jayawardene)."
        ],
        "lasith_malinga": [
            "I am famous for my round-arm 'slinga' action and lethal dipping toe-crushers.",
            "I am the only bowler in history to take 4 wickets in 4 consecutive balls twice in international cricket.",
            "I captained Sri Lanka to the ICC Men's T20 World Cup title in 2014.",
            "I took 338 ODI wickets and 107 T20I wickets, including 3 ODI hat-tricks.",
            "I defended 9 runs in the final over of the 2019 IPL final to win the title for Mumbai Indians."
        ],
        "jacques_kallis": [
            "I am widely considered the greatest all-rounder in the history of modern cricket.",
            "I represented South Africa and scored 13,289 Test runs (45 centuries) and 11,579 ODI runs (17 centuries).",
            "I took 292 Test wickets and 273 ODI wickets with my brisk medium-fast bowling.",
            "I am the only player in history with 10,000+ runs and 250+ wickets in both Tests and ODIs.",
            "I took 338 international catches, standing as a legendary slip fielder."
        ],
        "kapil_dev": [
            "I captained India to their historic maiden ICC World Cup title at Lord's in 1983.",
            "I famously scored a match-winning 175 not out against Zimbabwe from 17/5 in the 1983 World Cup.",
            "I retired as the world's highest Test wicket-taker with 434 Test wickets.",
            "I never bowled a single no-ball in my entire 16-year international career.",
            "I scored 5,248 Test runs and took 434 wickets as India's greatest pace-bowling all-rounder."
        ],
        "sunil_gavaskar": [
            "I am known as the 'Little Master' and the original master of classical opening batting.",
            "I scored 774 runs in my debut Test series against the mighty West Indies in 1971.",
            "I was the first batter in cricket history to reach 10,000 Test match runs (1987).",
            "I scored 34 Test centuries without wearing a helmet against the most ferocious fast bowlers.",
            "I finished my Test career with 10,122 runs in 125 matches at an average of 51.12."
        ],
        "adam_gilchrist": [
            "I revolutionized the role of the wicket-keeper batsman in modern international cricket.",
            "I won three consecutive ICC Cricket World Cups with Australia in 1999, 2003, and 2007.",
            "I famously batted with a squash ball in my left glove while scoring 149 in the 2007 World Cup Final.",
            "I scored 9,619 ODI runs at a blistering strike rate of 96.94 with 16 centuries.",
            "I completed 905 international dismissals (813 catches and 92 stumpings) as wicket-keeper."
        ],
        "anil_kumble": [
            "I was nicknamed 'Jumbo' for my pace off the pitch and unmatched competitive grit.",
            "I became only the second bowler in Test history to take all 10 wickets in an innings (10/74 vs Pakistan in 1999).",
            "I bowled with a broken, bandaged jaw in Antigua in 2002, famously dismissing Brian Lara.",
            "I am India's all-time leading wicket-taker with 619 Test wickets and 337 ODI wickets.",
            "I finished with 956 international wickets, the fourth-highest in cricket history."
        ],
        "viv_richards": [
            "I was universally known as 'The Master Blaster' and batted without a helmet with supreme swagger.",
            "I scored a match-winning 138 not out in the 1979 ICC World Cup Final at Lord's.",
            "I smashed a 56-ball Test century against England in 1986, which stood as the fastest for 30 years.",
            "I scored 8,540 Test runs and 6,721 ODI runs at a ferocious strike rate ahead of my era.",
            "I won two World Cups with the West Indies (1975 & 1979) and never lost a Test series as captain."
        ],
        "brendon_mccullum": [
            "I am the fearless Kiwi captain who ignited the revolutionary aggressive 'Bazball' mindset.",
            "I hold the record for the fastest century in Test cricket history off just 54 balls (vs Australia in 2016).",
            "I scored the first-ever IPL century (158* off 73 balls for KKR) on the tournament's opening night in 2008.",
            "I captained New Zealand to their first-ever ICC Cricket World Cup Final in 2015.",
            "I scored 14,676 international runs with 300+ international sixes across all formats."
        ],
        "shahid_afridi": [
            "I am beloved across the world as 'Boom Boom' for my explosive batting and quick leg-spin.",
            "I smashed a 37-ball ODI century against Sri Lanka in 1996 in just my second international match.",
            "I was named Player of the Match in both the semi-final and final of the 2009 ICC T20 World Cup.",
            "I hit 476 international sixes and took 395 ODI wickets for Pakistan.",
            "I took 541 international wickets and accumulated over 11,000 international runs."
        ],
        "courtney_walsh": [
            "I formed one of the most fearsome fast bowling duos in cricket history alongside Curtly Ambrose.",
            "I was the first bowler in cricket history to reach 500 Test wickets (in 2001).",
            "I captured 519 Test wickets in 132 matches for the West Indies.",
            "I famously took 5 wickets for just 1 run (5/1) against Sri Lanka in Sharjah in 1993.",
            "I took 746 international wickets across my marathon 17-year international career."
        ],
        "james_anderson": [
            "I am the only fast bowler in cricket history to reach 700 Test wickets.",
            "I claimed 704 Test wickets across 188 Test matches for England, bowling with sublime swing and seam.",
            "I played international cricket across four different decades from 2002 to 2024.",
            "I took 991 international wickets across all formats, the most by any pace bowler in history.",
            "I formed an iconic bowling partnership with Stuart Broad, taking over 1,000 Test wickets together."
        ],
        "pat_cummins": [
            "I captained Australia to victory in the 2023 ICC World Test Championship and 2023 ODI World Cup.",
            "I became the first bowler in history to take hat-tricks in consecutive matches at the 2024 ICC T20 World Cup.",
            "I was named ICC Men's Cricketer of the Year (Sir Garfield Sobers Trophy) in 2023.",
            "I debuted as an 18-year-old taking 6/79 and hitting the winning runs in Johannesburg in 2011.",
            "I have captured over 500 international wickets with elite pace, bounce, and lower-order hitting."
        ],
        "rashid_khan": [
            "I am the Afghan leg-spin wizard famous for my lightning-fast arm speed and unpickable googlies.",
            "I became the youngest player to captain an international cricket team at age 19.",
            "I became the fastest bowler to reach 100 ODI wickets (in just 44 matches).",
            "I have captured over 380 international wickets while dominating T20 leagues worldwide.",
            "I took a hat-trick in four consecutive balls in a T20I against Ireland in 2019."
        ],
        "ravichandran_ashwin": [
            "I am the master Indian off-spinner and tactical maestro with over 500 Test wickets.",
            "I have won 11 Player of the Series awards in Test cricket, tied for the second-most in history.",
            "I have claimed 37 five-wicket hauls in Test matches and scored 5 Test centuries.",
            "I was part of India's winning squads in the 2011 ODI World Cup and 2013 ICC Champions Trophy.",
            "I have taken 764 international wickets across all three formats for India."
        ],
        "sanath_jayasuriya": [
            "I transformed ODI cricket forever with pinch-hitting aggression in the 1996 World Cup.",
            "I was named Player of the Tournament in Sri Lanka's 1996 ICC Cricket World Cup triumph.",
            "I scored 13,430 ODI runs with 28 centuries and took 323 ODI wickets with my left-arm spin.",
            "I scored 340 in a Test match against India in 1997, part of a world-record 952/6 total.",
            "I hit 352 international sixes and claimed 440 international wickets."
        ],
        "mahela_jayawardene": [
            "I was one of the most elegant and tactical batting captains in Sri Lankan cricket history.",
            "I scored a magnificent century (103*) in the 2011 ICC Cricket World Cup Final in Mumbai.",
            "I shared the highest partnership in Test cricket history: 624 runs with Kumar Sangakkara.",
            "I scored 374 in a Test innings against South Africa in Colombo in 2006.",
            "I scored 25,957 international runs and took 440 catches across my legendary career."
        ],
        "sourav_ganguly": [
            "I am revered as 'Dada' and the 'Prince of Kolkata' for my fearless leadership.",
            "I scored 131 on my Test debut at Lord's in 1996.",
            "I led India to the 2003 ICC Cricket World Cup Final and a historic Test series draw in Australia.",
            "I scored 11,363 ODI runs (22 centuries) and formed a legendary opening partnership with Sachin.",
            "I won 4 consecutive Man of the Match awards in the 1997 Sahara Cup against Pakistan."
        ],
        "rahul_dravid": [
            "I earned the iconic moniker 'The Wall' for my impenetrable defensive technique and grit.",
            "I faced 31,258 balls and batted for 44,152 minutes in Test cricket, the most in history.",
            "I scored 13,288 Test runs (36 centuries) and 10,889 ODI runs (12 centuries) for India.",
            "I took 210 catches in Test matches, the world record for a non-wicketkeeper.",
            "I coached India to glory in the 2024 ICC Men's T20 World Cup."
        ],
        "yuvraj_singh": [
            "I was named Player of the Tournament in India's triumphant 2011 ICC Cricket World Cup campaign.",
            "I smashed 6 sixes in an over off Stuart Broad in the 2007 ICC T20 World Cup in Durban.",
            "I scored 8,701 ODI runs and took 111 wickets as an elite middle-order match-winner.",
            "I scored 362 runs and took 15 wickets in the 2011 World Cup, winning 4 Man of the Match awards.",
            "I hit the fastest fifty in T20 international history off just 12 balls."
        ],
        "zaheer_khan": [
            "I was the spearhead of India's pace attack and master of the knuckleball and reverse swing.",
            "I was the joint-leading wicket-taker in the 2011 ICC Cricket World Cup with 21 wickets.",
            "I captured 311 Test wickets and 282 ODI wickets across my 14-year international career.",
            "I took 611 international wickets across all formats for India.",
            "I bowled the opening maiden over and set the tone in the 2011 World Cup Final against Sri Lanka."
        ],
        "steve_waugh": [
            "I was the gritty Australian captain who led the era of 'Mental Disintegration' and undefeated domination.",
            "I captained Australia to victory in the 1999 ICC Cricket World Cup.",
            "I scored 120 not out against South Africa in the 1999 World Cup Super Six thriller.",
            "I scored 10,927 Test runs with 32 centuries and 7,569 ODI runs for Australia.",
            "I led Australia to a world-record 16 consecutive Test match victories."
        ]
    }

    STAT_CATEGORIES = [
        {"key": "odi_runs", "label": "ODI Runs", "target_roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
        {"key": "test_runs", "label": "Test Runs", "target_roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
        {"key": "test_wickets", "label": "Test Wickets", "target_roles": ["Bowler", "All-Rounder"]},
        {"key": "odi_wickets", "label": "ODI Wickets", "target_roles": ["Bowler", "All-Rounder"]},
        {"key": "international_runs", "label": "International Runs", "target_roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
        {"key": "international_wickets", "label": "International Wickets", "target_roles": ["Bowler", "All-Rounder"]},
        {"key": "international_centuries", "label": "International Centuries", "target_roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
        {"key": "international_sixes", "label": "International Sixes", "target_roles": ["Batter", "All-Rounder", "Wicket-Keeper", "Bowler"]},
        {"key": "wk_dismissals", "label": "WK Dismissals", "target_roles": ["Wicket-Keeper"]},
        {"key": "wk_stumpings", "label": "WK Stumpings", "target_roles": ["Wicket-Keeper"]},
        {"key": "captaincy_wins", "label": "Captaincy Wins", "target_roles": ["Batter", "Bowler", "All-Rounder", "Wicket-Keeper"]},
        {"key": "test_five_wickets", "label": "Test 5-Wkt Hauls", "target_roles": ["Bowler", "All-Rounder"]},
        {"key": "international_catches", "label": "International Catches", "target_roles": ["Batter", "Bowler", "All-Rounder", "Wicket-Keeper"]},
        {"key": "t20i_runs", "label": "T20I Runs", "target_roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
        {"key": "odi_fifties", "label": "ODI Fifties", "target_roles": ["Batter", "All-Rounder", "Wicket-Keeper"]},
    ]

    TIMELINE_SETS = [
        ["sachin_tendulkar", "ricky_ponting", "ms_dhoni", "virat_kohli"],
        ["wasim_akram", "shane_warne", "ab_de_villiers", "jasprit_bumrah"],
        ["brian_lara", "jacques_kallis", "rohit_sharma", "shaheen_afridi"],
        ["glenn_mcgrath", "chris_gayle", "dale_steyn", "pat_cummins"],
        ["muttiah_muralitharan", "kumar_sangakkara", "lasith_malinga", "rashid_khan"],
        ["kapil_dev", "anil_kumble", "yuvraj_singh", "jasprit_bumrah"],
        ["sunil_gavaskar", "wasim_akram", "ms_dhoni", "pat_cummins"],
        ["viv_richards", "brian_lara", "ab_de_villiers", "shaheen_afridi"],
        ["courtney_walsh", "jacques_kallis", "dale_steyn", "rashid_khan"],
        ["steve_waugh", "ricky_ponting", "ben_stokes", "pat_cummins"],
        ["sanath_jayasuriya", "kumar_sangakkara", "lasith_malinga", "shaheen_afridi"],
        ["sourav_ganguly", "ms_dhoni", "virat_kohli", "jasprit_bumrah"],
    ]

    def __init__(self):
        self.players = CRICKET_PLAYERS_DATA
        self.seen_who_am_i = []
        self.seen_hl_pairs = []
        self.seen_sof_ids = []
        self.seen_timelines = []
        self.seen_guess_ids = []

    def generate_who_am_i(self) -> Dict[str, Any]:
        """Generates a progressive clue challenge without repeating recent players."""
        eligible = [p for p in self.players if p["id"] not in self.seen_who_am_i]
        if not eligible:
            self.seen_who_am_i.clear()
            eligible = self.players

        player = random.choice(eligible)
        pid = player["id"]
        self.seen_who_am_i.append(pid)
        if len(self.seen_who_am_i) > 50:
            self.seen_who_am_i.pop(0)
        
        if pid in self.WHO_AM_I_CUSTOM_CLUES:
            clues = self.WHO_AM_I_CUSTOM_CLUES[pid]
        else:
            clues = [
                f"I represented {player['country']} on the international stage.",
                f"My primary role in the team was {player['role']} ({player['batting_style']}).",
                f"My international career span was {player['career_span']}.",
                f"I registered {player['international_runs']} International Runs and {player['international_wickets']} Wickets.",
                f"In ODIs, I scored {player['odi_runs']} runs with {player['odi_centuries']} centuries.",
            ]
        
        # 4 choices
        choices = [player["name"]]
        other_players = [p for p in self.players if p["id"] != player["id"]]
        distractors = random.sample(other_players, 3)
        choices.extend([d["name"] for d in distractors])
        random.shuffle(choices)

        return {
            "type": "who_am_i",
            "target_id": player["id"],
            "target_name": player["name"],
            "clues": clues,
            "options": choices,
            "country": player["country"],
            "role": player["role"]
        }

    def generate_higher_lower(self) -> Dict[str, Any]:
        """Generates a smart Higher or Lower challenge between 2 appropriate players for a stat."""
        stat_cat = random.choice(self.STAT_CATEGORIES)
        stat_key = stat_cat["key"]
        stat_label = stat_cat["label"]
        allowed_roles = stat_cat["target_roles"]

        eligible_players = [p for p in self.players if p["role"] in allowed_roles]
        if len(eligible_players) < 2:
            eligible_players = self.players

        p1 = random.choice(eligible_players)
        p2 = random.choice(eligible_players)
        attempts = 0
        pair_key = f"{p1['id']}_{p2['id']}_{stat_key}"
        while (p1["id"] == p2["id"] or p1[stat_key] == p2[stat_key] or pair_key in self.seen_hl_pairs) and attempts < 25:
            p1 = random.choice(eligible_players)
            p2 = random.choice(eligible_players)
            pair_key = f"{p1['id']}_{p2['id']}_{stat_key}"
            attempts += 1

        self.seen_hl_pairs.append(pair_key)
        if len(self.seen_hl_pairs) > 50:
            self.seen_hl_pairs.pop(0)

        return {
            "type": "higher_lower",
            "stat_key": stat_key,
            "stat_label": stat_label,
            "player_a": {
                "id": p1["id"],
                "name": p1["name"],
                "country": p1["country"],
                "role": p1["role"],
                "stat_key": stat_key,
                "stat_label": stat_label,
                "stat_value": p1[stat_key]
            },
            "player_b": {
                "id": p2["id"],
                "name": p2["name"],
                "country": p2["country"],
                "role": p2["role"],
                "stat_key": stat_key,
                "stat_label": stat_label,
                "stat_value": p2[stat_key]
            },
            "is_higher": p2[stat_key] > p1[stat_key],
            "is_lower": p2[stat_key] < p1[stat_key],
            "is_equal": p2[stat_key] == p1[stat_key]
        }

    def generate_stat_or_fiction(self) -> Dict[str, Any]:
        """Returns a true/false statement without repeating recent 50 questions."""
        available = [q for q in self.STAT_FICTION_QUESTIONS if q["id"] not in self.seen_sof_ids]
        if not available:
            self.seen_sof_ids.clear()
            available = self.STAT_FICTION_QUESTIONS

        q = random.choice(available)
        self.seen_sof_ids.append(q["id"])
        if len(self.seen_sof_ids) > 50:
            self.seen_sof_ids.pop(0)

        return {
            "type": "stat_or_fiction",
            "id": q["id"],
            "statement": q["statement"],
            "is_true": q["is_true"],
            "explanation": q["explanation"]
        }

    def generate_career_timeline(self) -> Dict[str, Any]:
        """Pick a curated set of 4 players with strictly distinct debut years."""
        available_sets = [s for s in self.TIMELINE_SETS if "_".join(s) not in self.seen_timelines]
        if not available_sets:
            self.seen_timelines.clear()
            available_sets = self.TIMELINE_SETS

        set_ids = random.choice(available_sets)
        self.seen_timelines.append("_".join(set_ids))
        if len(self.seen_timelines) > 50:
            self.seen_timelines.pop(0)

        chosen = [get_cricket_player_by_id(pid) for pid in set_ids if get_cricket_player_by_id(pid)]
        if len(chosen) < 4:
            chosen = random.sample(self.players, 4)
        
        # Sort by start year
        def get_start_year(p: Dict[str, Any]) -> int:
            try:
                return int(p["career_span"].split("–")[0].strip())
            except Exception:
                return 2000

        correct_order = sorted(chosen, key=get_start_year)
        shuffled = list(chosen)
        random.shuffle(shuffled)

        return {
            "type": "career_timeline",
            "shuffled_players": [
                {"id": p["id"], "name": p["name"], "country": p["country"], "span": p["career_span"], "start_year": get_start_year(p)}
                for p in shuffled
            ],
            "correct_order": [p["id"] for p in correct_order],
            "correct_names": [p["name"] for p in correct_order]
        }

    def generate_guess_player(self) -> Dict[str, Any]:
        """Multiple choice question with icon/flag/stat hints without repeating recent players."""
        available = [p for p in self.players if p["id"] not in self.seen_guess_ids]
        if not available:
            self.seen_guess_ids.clear()
            available = self.players

        player = random.choice(available)
        self.seen_guess_ids.append(player["id"])
        if len(self.seen_guess_ids) > 50:
            self.seen_guess_ids.pop(0)

        other_players = [p for p in self.players if p["id"] != player["id"]]
        distractors = random.sample(other_players, 3)
        choices = [player["name"]] + [d["name"] for d in distractors]
        random.shuffle(choices)

        hints = [
            f"Flag: {player['country']}",
            f"Role: {player['role']}",
            f"Style: {player['batting_style']} | {player['bowling_style']}",
            f"Int'l Runs: {player['international_runs']} | Int'l Wickets: {player['international_wickets']}"
        ]

        return {
            "type": "guess_player",
            "target_id": player["id"],
            "target_name": player["name"],
            "hints": hints,
            "options": choices
        }
