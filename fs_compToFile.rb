
require 'rubygems'
require 'bindata'

class AssocUsage < BinData::Record
        endian :big
#       safe_unpack16(&ver, buffer);
        uint16 :ver
#       safe_unpack_time(&buf_time, buffer);
        uint64 :time
        array :assocs, :read_until => :eof do
#               safe_unpack32(&assoc_id, buffer);
                uint32 :assoc_id
#               safe_unpack64(&usage_raw, buffer);
                uint64 :usage_raw
#               safe_unpack64(&usage_energy_raw, buffer);
#                 uint64 :usage_energy_raw
#               safe_unpack32(&grp_used_wall, buffer);
                uint32 :grp_used_wall
        end
end



factors_raw = 'root,118685966700.522,0.0
root/root,0.0,0.0
user353,32427332.2590216,0.0
user288,3913197676.79318,0.0
user16,3.47012525855573,0.0
user69,11477.2586812889,0.0
user340,4517869.5491153,0.0
user426,25282949.1524962,0.0
user4,83580106.0205429,0.0
user234,135.96763647394,0.0
user118,85729796.1733117,0.0
user371,264375.723729467,0.0
user31,2521.09891997835,0.0
user475,8646557.26678063,0.0
user294,46607116.4592775,0.0
user45,10.8852582564422,0.0
user584,178253600.991041,0.0
user47,10820339.040489,0.0
user286,744.942403447628,0.0
user204,811718911.76104,0.0
user636,26043696.0716741,0.0
user423,567341240.40465,0.0
user266,6304696.13061518,0.0
user88,1944.72290116648,0.0
user390,3923430.07679576,0.0
user308,5288617.84401386,0.0
user344,26539742.9939667,0.0
user474,926.493255277107,0.0
user670,84413822.810389,0.0
user609,64853491.4216784,0.0
user1,4079.38470718416,0.0
user135,35480126600.6253,0.0
user468,4328486.96678736,0.0
user51,34221472.1833377,0.0
user24,541640755.914239,0.0
user128,4354259.92302322,0.0
user2,1246749.16373948,0.0
user62,226849956.404735,0.0
user275,11572.0817236038,0.0
user510,518854567.6773,0.0
user129,37.714293492494,0.0
user462,168376.137112646,0.0
user319,1099842509.54805,0.0
user631,111629912.576404,0.0
user34,1011047.14379265,0.0
user443,14888219.8028956,0.0
user485,77601910.481553,0.0
user621,985097.971231721,0.0
user21,37757.5341909726,0.0
user373,11314369.9526754,0.0
user35,0.505801108674366,0.0
user287,100093346.623738,0.0
user245,171647082.2037,0.0
user301,740926.903831633,0.0
user175,48205612.9531932,0.0
user341,1262584800.32182,0.0
user60,213.654732589217,0.0
user490,6496260.52223123,0.0
user113,371.208135970221,0.0
user506,289612587.496119,0.0
user387,12990824000.4032,0.0
user632,167648491.993544,0.0
user66,51885.1244101731,0.0
user556,71405384.7335404,0.0
user338,888374.031552526,0.0
user50,1302012906.55886,0.0
user156,21135124.0893107,0.0
user5,2390475.51203864,0.0
user327,48939095.7507355,0.0
user392,325901805.080993,0.0
user348,12056978.7444538,0.0
user625,15807025.4655675,0.0
user393,6139264.85646329,0.0
user398,19237627.6729547,0.0
user61,88646859.7123724,0.0
user59,14374104.5524829,0.0
user299,141381.626213672,0.0
user165,121839672.557873,0.0
user455,923455.301731024,0.0
user316,394928608.204866,0.0
user39,1656912353.60208,0.0
user324,11261511.1612178,0.0
user267,5401377.27141054,0.0
user303,1343744.47752473,0.0
user101,0.457674476737338,0.0
user200,3962.15575890447,0.0
user311,1564421.98431007,0.0
user123,354094963.335582,0.0
user333,279.045790971887,0.0
user320,9503994.23263986,0.0
user167,46493613.6323923,0.0
user79,172.24605654614,0.0
user330,32262026.3254461,0.0
user518,1352293.57763671,0.0
user651,470029987.641503,0.0
user96,19668183.9308871,0.0
user495,142835562.309459,0.0
user160,139741471.905231,0.0
user270,388717369.018668,0.0
user14,90988.4595044386,0.0
user231,2845.8825562113,0.0
user331,58701.8790371548,0.0
user521,55171916.0857232,0.0
user290,3903591844.46379,0.0
user126,445934849.414694,0.0
user304,7707180.05959743,0.0
user629,25725440.6383471,0.0
user6,13033.1283851932,0.0
user668,242495087.059007,0.0
user551,145044638.366915,0.0
user209,1526277.60743446,0.0
user124,3.40848616785152,0.0
user235,1136681793.3795,0.0
user97,302884440.373997,0.0
user464,119822004.916897,0.0
user313,9223192.06729656,0.0
user366,1665159655.44774,0.0
user8,341574992.680009,0.0
user395,65865544.3673097,0.0
user52,3864348788.02722,0.0
user459,2968061724.52809,0.0
user487,432305.055118077,0.0
user33,183934144.829618,0.0
user295,2551136092.69766,0.0
user376,51576063.9093367,0.0
user463,16379043.1857974,0.0
user401,712674.119663441,0.0
user305,69054812.1038059,0.0
user381,13395156.0686206,0.0
user685,1622025804.75124,0.0
user607,193877297.621386,0.0
user87,2614.2390984235,0.0
user648,53238300.5752902,0.0
user519,4334056.32424482,0.0
user174,535.573961731371,0.0
user19,499.914000845305,0.0
user152,69093697.7475064,0.0
user106,2.95435995166046,0.0
user7,37.3632504784703,0.0
user440,17145632.3027542,0.0
user312,83539596.1076891,0.0
user576,37990557.1561412,0.0
user389,288532.008581955,0.0
user335,42990809.232987,0.0
user214,132415.813467015,0.0
user317,110584473.633121,0.0
user613,12706405.144819,0.0
user23,0.00455024464988419,0.0
user105,5981639.02349263,0.0
user117,86.4396039657585,0.0
user449,67488060.7924092,0.0
user603,2888090.33896132,0.0
user349,2009416.93409473,0.0
user29,1020544.33035467,0.0
user285,202733.547372021,0.0
user143,11287388.7643131,0.0
user55,1.23964226268923,0.0
user325,614460955.751152,0.0
user554,10297743.6607178,0.0
user67,0.0620152344716961,0.0
user645,1163000.44329267,0.0
user323,72858693.3839301,0.0
user380,3986799.85194853,0.0
user93,136460.408079054,0.0
user691,13593616.3764485,0.0
user370,20076868.0062399,0.0
user109,0.326891471501812,0.0
user503,30776454.110086,0.0
user173,867925.636484719,0.0
user434,122747095.403741,0.0
user103,308.079052331038,0.0
user100,3.6083274429697,0.0
user345,264017.083387707,0.0
user334,1101161.63060593,0.0
user562,428044919.904293,0.0
user407,55787581.4696582,0.0
user542,244663.758664805,0.0
user284,61920023.4156238,0.0
user476,3981040.96763783,0.0
user515,82376318.2939361,0.0
user663,33995287.6496706,0.0
user606,32704721.3193802,0.0
user20,20742479.4649006,0.0
user125,8.13793561984921e-07,0.0
user575,4879939078.35175,0.0
user343,28611190.4266829,0.0
user588,148070945.988543,0.0
user439,6716839.09779993,0.0
user432,32881372.4168261,0.0
user555,22900655.7451331,0.0
user448,558818.62358406,0.0
user289,14475.0065137492,0.0
user577,116246082.333191,0.0
user208,368.427802424876,0.0
user94,5027.71431346332,0.0
user302,565146366.41895,0.0
user282,3164974428.8504,0.0
user15,68533.4669658138,0.0
user364,58918.5143464317,0.0
user678,87570019.7062921,0.0
user141,5658.02398411769,0.0
user134,276.518772514806,0.0
user675,443051716.56827,0.0
user656,483634046.604277,0.0
user386,336782005.95362,0.0
user36,66738091.673382,0.0
user274,7533.20493647684,0.0
user367,272847.302964838,0.0
user652,11736257.9629282,0.0
user329,7903208.91620456,0.0
user470,16476456.1875347,0.0
user326,1668375.18293908,0.0
user257,12652200.5681557,0.0
user544,119261.788187234,0.0
user136,10092959.1467373,0.0
user137,2502.62998024159,0.0
user297,7750004.37557822,0.0
user346,220420452.21774,0.0
user460,29870130.6982726,0.0
user622,9886632.84550891,0.0
user394,114117000.193123,0.0
user122,63300579.6515091,0.0
user690,3412303.86092802,0.0
user477,36034236.9506781,0.0
user509,124631994.917547,0.0
user478,86748.4718315813,0.0
user114,35791244.5332668,0.0
user99,0.586098103782809,0.0
user630,5312811.59750904,0.0
user579,360831492.999561,0.0
user538,3083126.3586238,0.0
user447,164800431.333666,0.0
user49,25695235.0214036,0.0
user595,11310299.1898019,0.0
user502,26281561.4778075,0.0
user41,0.0787087522781019,0.0
user598,267440137.470372,0.0
user350,1111845.0135177,0.0
user127,203670.815010787,0.0
user534,32221611.0824338,0.0
user435,76101143.4644304,0.0
user422,23120466.0240731,0.0
user561,8788.7894633808,0.0
user372,1928148.82129481,0.0
user347,16833997.2271116,0.0
user549,560133103.523264,0.0
user252,0.0116967986804685,0.0
user553,59603673.2561902,0.0
user18,4118.04032687645,0.0
user378,633822.003470428,0.0
user12,28420176.3989329,0.0
user30,4746011.65297875,0.0
user522,37953827.1736201,0.0
user634,2258267.71998632,0.0
user605,1670404.30420097,0.0
user63,0.0248178997701479,0.0
user391,22166.6214201579,0.0
user500,805196613.114599,0.0
user9,9.19856584254128,0.0
user511,53968801.9899442,0.0
user479,8984393.90668317,0.0
user520,72885180.6252889,0.0
user484,40643963.9827179,0.0
user480,98687437.104807,0.0
user121,0.292522129440607,0.0
user533,29870.1908913675,0.0
user363,206087.405891407,0.0
user268,59031256.2633563,0.0
user644,12858.560343988,0.0
user539,4671762.70382854,0.0
user10,53.080175215748,0.0
user570,5962019.38951513,0.0
user557,141159525.828431,0.0
user624,79863223.4393528,0.0
user11,3907.30519014533,0.0
user318,1216804.0428297,0.0
user489,1380504.90577705,0.0
user669,213680620.245261,0.0
user679,295223542.018834,0.0
user263,116209.608296215,0.0
user293,38418220.4595842,0.0
user298,10222959.4018529,0.0
user178,11617548.4905266,0.0
user402,424582.693151953,0.0
user342,30157550.9491693,0.0
user150,576.699284358755,0.0
user403,913442.289255632,0.0
user458,161163.34737009,0.0
user481,1413378.4329104,0.0
user89,20.1163392458682,0.0
user232,798.664354325276,0.0
user357,104205555.435643,0.0
user692,1997.65752516638,0.0
user95,16.4289845922707,0.0
user482,1.47860690496122,0.0
user254,8824.31605462469,0.0
user102,0.837441610949698,0.0
user569,93161620.2316361,0.0
user248,6.7013664142507,0.0
user279,1393561.9588409,0.0
user619,84684319.4968393,0.0
user688,61903032.8535657,0.0
user592,6045234.7892196,0.0
user593,13441649.411925,0.0
user543,64.7783554166683,0.0
user213,23695.7931233946,0.0
user201,1124450.1922068,0.0
user627,11656471.7409286,0.0
user375,705022788.229935,0.0
user130,0.852893756696858,0.0
user483,300008.523321644,0.0
user78,0.59025782965363,0.0
user260,287.638930302432,0.0
user58,616021.423273347,0.0
user261,202641453.002591,0.0
user552,1321373963.43033,0.0
user590,100640969.785317,0.0
user249,2175.81604851208,0.0
user641,9877597.85872837,0.0
user314,16797549.1822724,0.0
user513,29063973.1974241,0.0
user309,11569526.6181623,0.0
user110,560926.036587829,0.0
user82,0.0157079472753321,0.0
user589,15993867.4943489,0.0
user131,0.944448828626925,0.0
user456,257410.555084247,0.0
user494,2494150.70280885,0.0
user199,108.599272654301,0.0
user351,15.1813269221821,0.0
user425,441346.833581759,0.0
user545,114935.863198,0.0
user132,91.3716520896009,0.0
user133,1864.65125159958,0.0
user352,21.0941383171356,0.0
user512,2594688.09717942,0.0
user517,147234.150952915,0.0
user148,21.0157321795719,0.0
user667,49221138.7114655,0.0
user647,1028740808.91287,0.0
user535,47046723.4518641,0.0
user240,6.52613895503679,0.0
user566,11999564.8667618,0.0
user491,351013392.115785,0.0
user13,2.83046336809082e-05,0.0
user617,113017245.717674,0.0
user17,492.508710989443,0.0
user271,75325.9056025639,0.0
user111,57.2313612777012,0.0
user56,9.02336339996186,0.0
user451,193118.172500771,0.0
user28,5098.17582161327,0.0
user615,166848282.991809,0.0
user65,0.0799315512927552,0.0
user269,52.4453842183699,0.0
user84,2359.15080091802,0.0
user637,255352621.588557,0.0
user638,2695687.22696338,0.0
user339,3154.06324547776,0.0
user354,78537.4278586325,0.0
user22,0.000901936500229349,0.0
user514,356905.684041974,0.0
user25,7.77694645341927e-08,0.0
user379,381379.318965835,0.0
user355,7.06485120041004,0.0
user441,412807.928191055,0.0
user486,47999513.7944098,0.0
user574,865696.865480562,0.0
user369,756302.671154826,0.0
user163,366826.309294961,0.0
user170,0.0906868835911924,0.0
user238,34373183.2962977,0.0
user547,2517092369.50266,0.0
user272,23.4333032021749,0.0
user655,88474171.328597,0.0
user649,1451951.88349311,0.0
user497,220819771.059484,0.0
user466,24208005.2675859,0.0
user273,1186.12191625917,0.0
user693,24271692.0924033,0.0
user211,8130.06515377009,0.0
user356,2.05094952718687,0.0
user361,3231920.38364552,0.0
user233,909.164480096231,0.0
user368,4550417886.61848,0.0
user445,7371590.96312249,0.0
user433,450552834.949691,0.0
user639,25324336.4233712,0.0
user501,74083037.2121609,0.0
user90,0.252363072145965,0.0
user610,39037952.3162462,0.0
user559,968109675.487273,0.0
user446,157180.912659718,0.0
user600,24171668.8325153,0.0
user471,230171.975497812,0.0
user540,852586.858852895,0.0
user496,951264.249353314,0.0
user358,71.5782052615061,0.0
user197,0.0995395995088992,0.0
user359,1850764.35599895,0.0
user242,121.071208100455,0.0
user548,10097125.849246,0.0
user220,0.270400819891241,0.0
user360,2.05018630258684,0.0
user596,103082219.997106,0.0
user563,23118.4444326597,0.0
user362,0.177985910952794,0.0
user616,144125036.537303,0.0
user488,10626949.0218574,0.0
user183,5286.49040936533,0.0
user195,590.028905853186,0.0
user198,158.256822610343,0.0
user187,179.277575416784,0.0
user172,2881623.4958323,0.0
user184,182.740816661439,0.0
user171,339.733539500388,0.0
user192,14315.401066621,0.0
user177,91.7729609448773,0.0
user467,31052512.0687287,0.0
user182,52800.7066869068,0.0
user564,6042790.9071517,0.0
user565,452413.050867968,0.0
user560,26274.1346847555,0.0
user300,328.262485501881,0.0
user54,2810480.93644837,0.0
user186,5366.83805243541,0.0
user38,0.0276594546926501,0.0
user138,2.68034121003538,0.0
user365,6786.47673902415,0.0
user322,88.7823851262841,0.0
user640,1835026.15195429,0.0
user684,166381.799030409,0.0
user689,41143263.6121996,0.0
user694,16716657.8856149,0.0
user695,17882127.7269559,0.0
user454,121990.92200827,0.0
user139,0.0047664226758023,0.0
user493,13795.6197869467,0.0
user244,62.113692444938,0.0
user149,731.228018656888,0.0
user296,79.291059429518,0.0
user696,6527094.47352046,0.0
user697,10726422.2397049,0.0
user374,36.5558709129201,0.0
user276,0.0050081352418434,0.0
user404,1400487.18040713,0.0
user159,1868.76619100103,0.0
user26,0.000300520616419435,0.0
user277,2.56539520306725e-05,0.0
user278,413396.787817179,0.0
user27,0.000493868859571654,0.0
user567,141816805.379901,0.0
user499,2066699.3022641,0.0
user568,232.741134777692,0.0
user140,26727700.4215906,0.0
user457,21865318.1640728,0.0
user642,923466339.637104,0.0
user142,0.0135934898927788,0.0
user657,269170.915978565,0.0
user32,6.96801018029076e-05,0.0
user623,4391850.70536397,0.0
user643,12089370.2171247,0.0
user572,39542998.8242001,0.0
user578,165722949.290202,0.0
user104,1674.07497414749,0.0
user377,3.72977099741687,0.0
user280,0.0120627828765062,0.0
user683,456119.88000784,0.0
user682,15922629.8375113,0.0
user646,3.92448734063807,0.0
user168,21106.3098844521,0.0
user698,1422699.20023621,0.0
user37,0.000302015817161734,0.0
user281,123.866243760039,0.0
user382,0.0442732185524004,0.0
user40,0.000181352795104277,0.0
user492,69085772.8807009,0.0
user144,0.000131937018109036,0.0
user612,44134231.8986838,0.0
user571,2554993.33209135,0.0
user283,42.6490760822936,0.0
user42,1.30600343105313e-07,0.0
user699,32209064.0553291,0.0
user43,14895438.4912402,0.0
user145,18.8644770469761,0.0
user146,12.9536462587171,0.0
user189,13490.3684458247,0.0
user44,135688910.953711,0.0
user573,1017750.47537139,0.0
user196,9273.86951887759,0.0
user188,11621.0837813062,0.0
user626,4559657.11187162,0.0
user383,380.614122260732,0.0
user384,51545.3701444558,0.0
user650,31137738.5393777,0.0
user46,0.105277493844496,0.0
user537,10070831.0842149,0.0
user259,1584.88152119902,0.0
user315,22.3283203286745,0.0
user48,0.00487584477335539,0.0
user385,18.6427954387392,0.0
user583,3825496.45319986,0.0
user310,8358.88804349919,0.0
user427,8936.81305489763,0.0
user53,5.70612533575641,0.0
user580,0.138153578975392,0.0
user581,0.0348065783952593,0.0
user388,103.658392748629,0.0
user582,12096707.6791465,0.0
user436,4355571.3268191,0.0
user57,1.70913299568659e-05,0.0
user653,50747.1866925561,0.0
user64,6.19009309338339e-11,0.0
user68,0.0145249914855935,0.0
user654,611819.072509209,0.0
user332,136.154228546801,0.0
user70,0.0128825116806379,0.0
user71,0.00346648101148828,0.0
user72,8.06997678724013e-07,0.0
user73,4.04485056635387e-05,0.0
user74,0.00931493595951404,0.0
user75,177.342537183982,0.0
user76,10.3307221446141,0.0
user86,0.00151599884343486,0.0
user585,87357.0295987463,0.0
user157,4086.49683433838,0.0
user700,51217.2879857296,0.0
user523,8485117.5122507,0.0
user396,0.000594915805176853,0.0
user507,843219.011971239,0.0
user397,78.0335772932172,0.0
user399,40475.9553775802,0.0
user400,356.344233479735,0.0
user77,0.0707284327181757,0.0
user701,0.0,0.0
user586,5.65459587657572,0.0
user80,1.48197926729284e-05,0.0
user614,93251844.3908343,0.0
user587,153194.59850023,0.0
user702,0.0,0.0
user328,139.203074444671,0.0
user703,0.0,0.0
user81,0.00189725121967681,0.0
user674,720.568741285789,0.0
user83,21.7153649262501,0.0
user405,7.65803993622697,0.0
user406,95.1065652931538,0.0
user408,1.39470763639632,0.0
user409,27.917448020861,0.0
user410,7.32800467696552,0.0
user411,265.191534156425,0.0
user412,32.2134853294279,0.0
user413,53.3958570532745,0.0
user414,297.543609932716,0.0
user415,12.807334553754,0.0
user416,41.6543971122314,0.0
user417,11.4857877277736,0.0
user418,4.35455759337546,0.0
user419,0.0408430703338739,0.0
user420,513.874546867927,0.0
user85,1.57996398242451,0.0
user658,0.434249661760014,0.0
user147,0.474152870829464,0.0
user516,4784272.5765925,0.0
user591,81301.4727126203,0.0
user558,378430.010300567,0.0
user659,117391.475656717,0.0
user107,0.113649620201844,0.0
user421,1.08611880454944,0.0
user704,0.0,0.0
user151,4.78805541547354,0.0
user424,0.0623881922682243,0.0
user529,134343.315033396,0.0
user660,4823.00315477257,0.0
user428,566654.71370356,0.0
user429,17.5765672842516,0.0
user661,100968.481725628,0.0
user594,0.284839098187827,0.0
user292,43269.6535872742,0.0
user662,57068230.7073685,0.0
user508,484116.889022732,0.0
user597,1024596.31650828,0.0
user430,1.40690393588392,0.0
user431,6912072.32957031,0.0
user705,0.0,0.0
user620,88743730.5259877,0.0
user635,78255383.7016279,0.0
user706,0.0,0.0
user664,18566625.9762583,0.0
user153,0.022259695408642,0.0
user154,0.0856683213719839,0.0
user155,11.0410277464759,0.0
user437,19.8986642719563,0.0
user599,811007.798976481,0.0
user158,18.6271674165088,0.0
user601,856559.38384094,0.0
user438,136.776933112192,0.0
user707,0.0,0.0
user161,4.76602872163333,0.0
user602,14210367.1584917,0.0
user604,1891445.79064627,0.0
user708,0.0,0.0
user709,0.0,0.0
user162,0.0165083580872773,0.0
user164,0.0789692832751236,0.0
user166,10.6798367671343,0.0
user169,2.86660328836835,0.0
user176,24.4836500601628,0.0
user179,14.1560433460096,0.0
user180,6.39031478088142e-05,0.0
user181,0.00578606442573793,0.0
user91,0.96579119440641,0.0
user116,1.30691835457183,0.0
user185,41.5977981183329,0.0
user190,71.0004599114213,0.0
user191,0.00019531255733727,0.0
user193,80.3577017117423,0.0
user194,94.8837230343172,0.0
user442,44.6107173765715,0.0
user608,6.714673439107,0.0
user202,0.000448811744200524,0.0
user203,30.1017175686202,0.0
user611,38542.1978673775,0.0
user108,2.24486128053841,0.0
user205,5339.20972291419,0.0
user665,17446.6752720261,0.0
user206,1.73404847328297,0.0
user444,0.241897545977941,0.0
user498,601293.705309021,0.0
user666,357695.943695264,0.0
user618,6617.06943031032,0.0
user207,19.2829840211898,0.0
user710,0.0,0.0
user210,2.98450556659849,0.0
user711,0.0,0.0
user712,0.0,0.0
user212,0.738815622674521,0.0
user504,0.0224313550159681,0.0
user505,4.10556143144173,0.0
user450,4423.14197557757,0.0
user92,0.0380685316673322,0.0
user713,0.0,0.0
user237,7.78397615768159e-05,0.0
user452,370623.466232136,0.0
user453,3324996.96950533,0.0
user671,160337104.648024,0.0
user291,35.9782493389287,0.0
user714,0.0,0.0
user672,17505.1562352355,0.0
user673,2.97567636445281,0.0
user715,0.0,0.0
user716,0.0,0.0
user717,0.0,0.0
user718,0.0,0.0
user719,0.0,0.0
user250,0.0711837791762753,0.0
user676,5786189.05589731,0.0
user677,15770009.2610642,0.0
user215,0.019846555331265,0.0
user216,0.0786436759456571,0.0
user217,0.550660225652098,0.0
user218,0.00349627485258237,0.0
user219,0.0173665468534417,0.0
user221,0.124238282865767,0.0
user222,0.0275483933305901,0.0
user223,0.298211635941759,0.0
user224,0.474502071883668,0.0
user225,0.0134400034980727,0.0
user226,0.0146802675700498,0.0
user227,0.109310844974458,0.0
user228,0.0260158976048421,0.0
user229,0.182332437607374,0.0
user230,0.00669547472210774,0.0
user720,0.0,0.0
user680,15910.6722355268,0.0
user721,0.0,0.0
user524,8.92779804694413,0.0
user525,12.7569633808967,0.0
user526,4.92069369788845,0.0
user527,7.88547208439617,0.0
user528,9.55645003362019,0.0
user530,3.04816414858757,0.0
user531,1.40069829399485,0.0
user532,2.68346239736265,0.0
user722,0.0,0.0
user681,0.826860034380515,0.0
user633,3466087.75266459,0.0
user536,5.30854869269674,0.0
user236,0.956456838352443,0.0
user239,42.6141984167846,0.0
user98,0.0131556720856644,0.0
user306,1266.08021654276,0.0
user307,0.189339342264467,0.0
user541,69780.6523726165,0.0
user461,1715.79174337457,0.0
user241,22.0460897956475,0.0
user546,1.17700297590066,0.0
user628,20803.8046506303,0.0
user243,0.0,0.0
user246,9.58277831058426e-07,0.0
user112,2.69815744616617e-05,0.0
user321,0.00130039357722732,0.0
user115,3.65727791876189e-10,0.0
user247,4.27605133337421,0.0
user251,0.00121646923562167,0.0
user253,0.770488342591031,0.0
user255,0.0,0.0
user256,3.96443366505721e-05,0.0
user258,2.15367981824179,0.0
user262,68.1611208740723,0.0
user465,1967.79223324262,0.0
user686,257205127.48021,0.0
user687,89.5270068812353,0.0
user264,2.11998256175994e-06,0.0
user265,0.00371906509298624,0.0
user336,0.00243247672097399,0.0
user469,36.4185737645633,0.0
user472,0.00417976318303879,0.0
user119,8.23861733402801e-05,0.0
user120,0.0136964484065582,0.0
user550,997.996647484215,0.0
user473,22.0412233783275,0.0'

$output_file = 'assoc_usage.NEW'

factors = {}
factors_raw.split("\n").each do |line|
        e = line.split(',')
	factors[e[0]] = e[1,2]
end

p factors

p "------------------------------"
# cmdLine = `sacctmgr show Association format=ID,user,account -pn 2>/dev/null`
cmdLine = "297||root|
298|root|root|
299||bench|
300|slurm|bench|
331||user114|
332|user114|user114|
311||user122|
312|user122|user122|
307||user135|
308|user135|user135|
439||user152|
440|user152|user152|
429||user160|
430|user160|user160|
415||user175|
416|user175|user175|
383||user204|
384|user204|user204|
397||user235|
398|user235|user235|
333||user24|
334|user24|user24|
339||user245|
340|user245|user245|
375||user261|
376|user261|user261|
345||user270|
346|user270|user270|
319||user282|
320|user282|user282|
403||user284|
404|user284|user284|
341||user288|
342|user288|user288|
347||user305|
348|user305|user305|
335||user319|
336|user319|user319|
325||user341|
326|user341|user341|
405||user347|
406|user347|user347|
417||user348|
418|user348|user348|
305||user366|
306|user366|user366|
317||user381|
318|user381|user381|
393||user386|
394|user386|user386|
385||user387|
386|user387|user387|
353||user39|
354|user39|user39|
303||user426|
304|user426|user426|
411||user435|
412|user435|user435|
371||user447|
372|user447|user447|
323||user451|
324|user451|user451|
427||user467|
428|user467|user467|
313||user47|
314|user47|user47|
391||user485|
392|user485|user485|
395||user49|
396|user49|user49|
435||user492|
436|user492|user492|
387||user51|
388|user51|user51|
357||user511|
358|user511|user511|
349||user512|
350|user512|user512|
419||user54|
420|user54|user54|
409||user547|
410|user547|user547|
369||user554|
370|user554|user554|
365||user556|
366|user556|user556|
389||user575|
390|user575|user575|
301||user584|
302|user584|user584|
401||user588|
402|user588|user588|
327||user593|
328|user593|user593|
407||user595|
408|user595|user595|
309||user600|
310|user600|user600|
337||user609|
338|user609|user609|
381||user616|
382|user616|user616|
399||user619|
400|user619|user619|
329||user622|
330|user622|user622|
377||user636|
378|user636|user636|
413||user640|
414|user640|user640|
437||user647|
438|user647|user647|
315||user651|
316|user651|user651|
425||user652|
426|user652|user652|
361||user656|
362|user656|user656|
431||user663|
432|user663|user663|
343||user668|
344|user668|user668|
433||user669|
434|user669|user669|
379||user670|
380|user670|user670|
351||user675|
352|user675|user675|
321||user678|
322|user678|user678|
441||user685|
442|user685|user685|
363||user691|
364|user691|user691|
367||user694|
368|user694|user694|
359||user696|
360|user696|user696|
355||user697|
356|user697|user697|
421||user698|
422|user698|user698|
423||user699|
424|user699|user699|
443||user700|
444|user700|user700|
373||user97|
374|user97|user97|"


idToUser = {}
userToId = {}
cmdLine.split("\n").each do |line|
        e = line.split('|')
        if e[1] != ""
                idToUser[e[0].to_i] = e[1]
                userToId[e[1]] = e[0].to_i
        end
end

p idToUser
p userToId



p "------------------------------"

d = AssocUsage.new
d.ver = 1
d.time = Time.now().to_i
factors.each do |f|
	p f
	if userToId[f[0]] != nil
		d.assocs << {
			"grp_used_wall"=>0,
			"usage_raw"=>f[1][0].to_i,
# 			"usage_energy_raw"=>f[1][1].to_i,
			"assoc_id"=>userToId[f[0]]}
p 'x'
	end
end

p "------------------------------"

print "\n"
print d.inspect
print "\n"

io = File.open($output_file, 'w')
p d.write(io)

p "------------------------------"



# rm /priority_last_decay_ran
# io = File.open('assoc_usage')
# r  = AssocUsage.read(io)
# print "\n"
# print r.inspect
# print "\n"
# io = File.open('assoc_usage.NEW', 'w')
# p r.write(io)

# r.assocs.each do |a|
# 	p a.assoc_id.to_s + ' X ' + a.usage_raw.to_s
# end
