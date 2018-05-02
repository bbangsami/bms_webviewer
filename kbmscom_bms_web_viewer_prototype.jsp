<%@ page contentType="text/html; charset=utf-8" language="java" buffer="1024kb"  import="java.sql.*, java.io.*, java.util.*, java.net.*, java.text.*, member.bms_webview" errorPage="" %>
<%@ page import="java.util.zip.*" %>
<%
request.setCharacterEncoding("UTF-8");
%>
<%
/* Github Prototype NOT USE 
Connection conn = null;

DBConn db = new DBConn();
conn = db.getConnection();

String cdn_root = "";
cdn_root = db.CDN_ROOT();
cdn_root += "bms_webviewer/";
*/

%>
<%

String get_file_number = "";
get_file_number = request.getParameter("file_no");
if("".equals(get_file_number) || get_file_number == null || "null".equals(get_file_number)){
	get_file_number = "_pcm_7another.zip";
}

String get_line_style = "";
get_line_style = request.getParameter("line_style");
if(("".equals(get_line_style) || get_line_style == null || "null".equals(get_line_style)) || (!"_4beat".equals(get_line_style) && !"_noline".equals(get_line_style))){
	get_line_style = "";
}

String get_zipnum = "1";
int int_get_zipnum = 1;
get_zipnum = request.getParameter("zipnum");
if("".equals(get_zipnum) || get_zipnum == null || "null".equals(get_zipnum)){
	get_zipnum = "1";
	int_get_zipnum = 1;
}
try{
	int_get_zipnum = Integer.parseInt(get_zipnum);
}catch(NumberFormatException e){
	get_zipnum = "1";
	int_get_zipnum = 1;
}



%>
<%
//bms읽기

//기본정보
String label_player = "9";
String label_genre = "";
String label_title = "";
String label_artist = "";
String label_bpm = "";
float float_bpm = 100;	//BPM 실수값
boolean already_bpm_read = false;
String label_playlevel = "";
int int_playlevel = 0;	//난이도 정수값
String label_rank = ""; 
int int_rank = 3;		//판정난이도 정수값
String label_totals = "";
int int_totals = 0;		//게이지증강량 정수값
String label_difficulty = "";
String label_subartist = "";
String label_lnobj = "_NO_long";	//롱노트처리 노트가 있는지

String label_speed_read = "";
float float_bpm_change[] = new float[256];	//bpm변경 (#xxx08) , #BPMyy
int count_bpm_change = 0;
int count_bpm_change_now_num = 1;
int int_stoptime[] = new int[256];	//스톱시간 (#xxx09) , #STOPyy
int count_stoptime = 0;
int count_stoptime_now_num = 1;
boolean exist_stop = false;
boolean random_bms = false;
boolean bms_read_end = false;
String random_count = "";


//메인정보
String main_bakja[] = new String[1002];				//#xxx02:박자
String main_bpm_change_small[] = new String[1002];	//#xxx03:BPM변경(16진수) [255이하]
String main_bpm_change_big[] = new String[1002];	//#xxx08:BPM변경(소숫점과 256이상, 10진수)
String main_stoptime[] = new String[1002];			//#xxx09:스톱시간(10진수)

String main_1p[][] = new String[9][1002];			//#xxx16:스크
String main_2p[][] = new String[9][1002];			//#xxx26:스크
String main_1p_old_ln[][] = new String[9][1002];	//#xxx56:스크
String main_2p_old_ln[][] = new String[9][1002];	//#xxx66:스크
int main_string_to_int = 0;
int max_noteline = 5;
String css_block_type = "scr";
String bms_key_type = "5";
String stop_sequence_width_size = "231";
String stop_sequence_align = "right";
String output_width_size = "240";
boolean six_n_seven_key = false;
boolean double_mode = false;
boolean pms_enable = true;
boolean old_long_note_type = false;
boolean bpm_change = false;
boolean bpm_change_new_type = false;
boolean bpm_change_old_type = false;
boolean stop_sequence = false;



String bms_file_loc = application.getRealPath("/");
String bms_file_name = "_pcm_7another.zip";	//추후 DB에서 읽어오기

bms_file_name = get_file_number; //임시

String bms_file_type = "";
String bms_file_real_name = "";
boolean read_enable = false;
boolean bms_load_complete = true;
boolean bms_is_zip = false;
boolean normal_file_read = false;
int choose_in_zip_file = 0;
bms_file_loc += "board/append_bms/" + "test_bms/";
bms_file_loc += bms_file_name;

ZipEntry zip_bms_entry = null;
InputStream bms_fileinput_zip = null;
FileInputStream bms_fileinput = null;
String in_zip_extension = "";


//일단 zip부터 확인
if(bms_file_name.length() > 4){
	int int_file_type_index = bms_file_name.lastIndexOf(".");
	bms_file_type = bms_file_name.substring(int_file_type_index);
}

if(".zip".equals(bms_file_type) || ".bms".equals(bms_file_type) || ".bme".equals(bms_file_type) || ".bml".equals(bms_file_type) || ".pms".equals(bms_file_type)){
	//확장자 점검
	read_enable = true;
}

if(".zip".equals(bms_file_type)){
	try {
    	ZipFile zipFile = new ZipFile(bms_file_loc);
    	Enumeration<? extends ZipEntry> entries = zipFile.entries();

    	while(entries.hasMoreElements()){
        	zip_bms_entry = entries.nextElement();
			in_zip_extension = zip_bms_entry.getName();
			in_zip_extension = in_zip_extension.substring(in_zip_extension.lastIndexOf("."), in_zip_extension.length());
			if(".bms".equals(in_zip_extension) || ".bme".equals(in_zip_extension) || ".bml".equals(in_zip_extension) || ".pms".equals(in_zip_extension)){
				//읽어올 확장자 제한
				choose_in_zip_file++;
				if(int_get_zipnum == choose_in_zip_file){
					bms_file_real_name = zip_bms_entry.getName();
					bms_fileinput_zip = zipFile.getInputStream(zip_bms_entry);
					bms_is_zip = true;
				}
			}
    	}
	}
	catch (final IOException ioe) {
    	bms_is_zip = false;
	}
}

//파일 읽기
try{
	BufferedReader br = null;
	
	if(!bms_is_zip){
		//zip이 아닐경우
		bms_fileinput = new FileInputStream(bms_file_loc);
		br = new BufferedReader(new InputStreamReader(bms_fileinput));
		bms_file_real_name = bms_file_name;
		normal_file_read = true;
	}else{
		//zip일 경우
		br = new BufferedReader(new InputStreamReader(bms_fileinput_zip));
	}

	String data;
	while((data= br.readLine())!= null && read_enable){
		//boolean때문에 변속구간부터 확인
		if(data.length() > 7 && "#BPM".equals(data.substring(0,4)) && already_bpm_read){
			label_speed_read = data.substring(7);
			count_bpm_change++;
			float_bpm_change[count_bpm_change] = Float.parseFloat(label_speed_read);
			count_bpm_change_now_num = count_bpm_change;
			// 한번 읽을떄마다 1씩 증가
		}
		
		if(data.length() > 8 && "#STOP".equals(data.substring(0,5))){
			label_speed_read = data.substring(8);
			count_stoptime++;
			int_stoptime[count_stoptime] = Integer.parseInt(label_speed_read);
			count_stoptime_now_num = count_stoptime;
			if(!exist_stop){ exist_stop = true; }
			// 한번 읽을떄마다 1씩 증가
		}
		
		if(data.length() > 8 && "#PLAYER".equals(data.substring(0,7))){
			label_player = data.substring(8);
		}
		if(data.length() > 7 && "#GENRE".equals(data.substring(0,6))){
			label_genre = data.substring(7);
		}
		if(data.length() > 7 && "#TITLE".equals(data.substring(0,6))){
			label_title = data.substring(7);
		}
		if(data.length() > 8 && "#ARTIST".equals(data.substring(0,7))){
			label_artist = data.substring(8);
		}
		if(data.length() > 5 && "#BPM".equals(data.substring(0,4)) && !already_bpm_read){
			label_bpm = data.substring(5);
			float_bpm = Float.parseFloat(label_bpm); 
			already_bpm_read = true;
			//처음읽는 BPM정보
		}
		if(data.length() > 11 && "#PLAYLEVEL".equals(data.substring(0,10))){
			label_playlevel = data.substring(11);
			int_playlevel = Integer.parseInt(label_playlevel);
		}
		if(data.length() > 6 && "#RANK".equals(data.substring(0,5))){
			label_rank = data.substring(6);
			int_rank = Integer.parseInt(label_rank);
		}
		if(data.length() > 7 && "#TOTAL".equals(data.substring(0,6))){
			label_totals = data.substring(7);
			int_totals = Integer.parseInt(label_totals);
		}
		if(data.length() > 12 && "#DIFFICULTY".equals(data.substring(0,11))){
			label_difficulty = data.substring(12);
		}
		if(data.length() > 11 && "#SUBARTIST".equals(data.substring(0,10))){
			label_subartist = data.substring(11);
		}
		if(data.length() > 7 && "#LNOBJ".equals(data.substring(0,6))){
			label_lnobj = data.substring(7);
		}
		if(data.length() > 8 && "#RANDOM".equals(data.substring(0,7))){
			random_count = data.substring(8);
			random_bms = true;
		}
		if(data.length() > 7 && "#ENDIF".equals(data.substring(0,6))){
			label_lnobj = data.substring(7);
			if(!bms_read_end){ bms_read_end = true; } 
		}
		
		
		
		//메인 정보 읽기
		if(data.length() > 7 && "#".equals(data.substring(0,1)) && !"WAV".equals(data.substring(1,4)) && !"BMP".equals(data.substring(1,4)) && !"BGA".equals(data.substring(1,4)) && ":".equals(data.substring(6,7)) && !bms_read_end){
			try{
				main_string_to_int = Integer.parseInt(data.substring(1,4));
			}catch(Exception e){
				main_string_to_int = 999;
			}
			
			if("02".equals(data.substring(4,6))){
				main_bakja[main_string_to_int] = data.substring(7);
				// 박자
			}else if("03".equals(data.substring(4,6))){
				main_bpm_change_small[main_string_to_int] = data.substring(7);
				if(!bpm_change){ bpm_change = true; }
				if(!bpm_change_old_type){ bpm_change_old_type = true; }
				// BPM변경(16진수) [255이하]
			}else if("08".equals(data.substring(4,6))){
				main_bpm_change_big[main_string_to_int] = data.substring(7);
				if(!bpm_change){ bpm_change = true; }
				if(!bpm_change_new_type){ bpm_change_new_type = true; }
				// BPM변경(소숫점과 256이상, 10진수)
				//├#BPM01 숫자
				//└#BPM02 숫자 등
			}else if("09".equals(data.substring(4,6))){
				main_stoptime[main_string_to_int] = data.substring(7);
				if(!stop_sequence){ stop_sequence = true; }
				// 스톱시간
				//├#STOP01 12
				//└#STOP02 16 등
			}else if("16".equals(data.substring(4,6))){
				main_1p[0][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				// 1P 스크 읽기
			}else if("11".equals(data.substring(4,6))){
				main_1p[1][main_string_to_int] = data.substring(7);
				// 1P 키1번
			}else if("12".equals(data.substring(4,6))){
				main_1p[2][main_string_to_int] = data.substring(7);
				// 1P 키2번
			}else if("13".equals(data.substring(4,6))){
				main_1p[3][main_string_to_int] = data.substring(7);
				// 1P 키3번
			}else if("14".equals(data.substring(4,6))){
				main_1p[4][main_string_to_int] = data.substring(7);
				// 1P 키4번
			}else if("15".equals(data.substring(4,6))){
				main_1p[5][main_string_to_int] = data.substring(7);
				// 1P 키5번
			}else if("18".equals(data.substring(4,6))){
				main_1p[6][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!six_n_seven_key){ six_n_seven_key = true; }
				// 1P 키6번
			}else if("19".equals(data.substring(4,6))){
				main_1p[7][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!six_n_seven_key){ six_n_seven_key = true; }
				// 1P 키7번
			}else if("26".equals(data.substring(4,6))){
				main_2p[0][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!double_mode){ double_mode = true; }
				// 2P 스크 읽기
			}else if("21".equals(data.substring(4,6))){
				main_2p[1][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!double_mode){ double_mode = true; }
				// 2P 키1번
			}else if("22".equals(data.substring(4,6))){
				main_2p[2][main_string_to_int] = data.substring(7);
				// 2P 키2번, PMS 6번
			}else if("23".equals(data.substring(4,6))){
				main_2p[3][main_string_to_int] = data.substring(7);
				// 2P 키3번, PMS 7번
			}else if("24".equals(data.substring(4,6))){
				main_2p[4][main_string_to_int] = data.substring(7);
				// 2P 키4번, PMS 8번
			}else if("25".equals(data.substring(4,6))){
				main_2p[5][main_string_to_int] = data.substring(7);
				// 2P 키5번, PMS 9번
			}else if("28".equals(data.substring(4,6))){
				main_2p[6][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!six_n_seven_key){ six_n_seven_key = true; }
				if(!double_mode){ double_mode = true; }
				// 2P 키6번
			}else if("29".equals(data.substring(4,6))){
				main_2p[7][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!six_n_seven_key){ six_n_seven_key = true; }
				if(!double_mode){ double_mode = true; }
				// 2P 키7번
			}else if("56".equals(data.substring(4,6))){
				main_1p_old_ln[0][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 1P 스크 읽기
			}else if("51".equals(data.substring(4,6))){
				main_1p_old_ln[1][main_string_to_int] = data.substring(7);
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 1P 키1번
			}else if("52".equals(data.substring(4,6))){
				main_1p_old_ln[2][main_string_to_int] = data.substring(7);
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 1P 키2번
			}else if("53".equals(data.substring(4,6))){
				main_1p_old_ln[3][main_string_to_int] = data.substring(7);
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 1P 키3번
			}else if("54".equals(data.substring(4,6))){
				main_1p_old_ln[4][main_string_to_int] = data.substring(7);
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 1P 키4번
			}else if("55".equals(data.substring(4,6))){
				main_1p_old_ln[5][main_string_to_int] = data.substring(7);
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 1P 키5번
			}else if("58".equals(data.substring(4,6))){
				main_1p_old_ln[6][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!six_n_seven_key){ six_n_seven_key = true; }
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 1P 키6번
			}else if("59".equals(data.substring(4,6))){
				main_1p_old_ln[7][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!six_n_seven_key){ six_n_seven_key = true; }
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 1P 키7번
			}else if("66".equals(data.substring(4,6))){
				main_2p_old_ln[0][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!double_mode){ double_mode = true; }
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 2P 스크 읽기
			}else if("61".equals(data.substring(4,6))){
				main_2p_old_ln[1][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!double_mode){ double_mode = true; }
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 2P 키1번
			}else if("62".equals(data.substring(4,6))){
				main_2p_old_ln[2][main_string_to_int] = data.substring(7);
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 2P 키2번, PMS 6번
			}else if("63".equals(data.substring(4,6))){
				main_2p_old_ln[3][main_string_to_int] = data.substring(7);
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 2P 키3번, PMS 7번
			}else if("64".equals(data.substring(4,6))){
				main_2p_old_ln[4][main_string_to_int] = data.substring(7);
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 2P 키4번, PMS 8번
			}else if("65".equals(data.substring(4,6))){
				main_2p_old_ln[5][main_string_to_int] = data.substring(7);
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 2P 키5번, PMS 9번
			}else if("68".equals(data.substring(4,6))){
				main_2p_old_ln[6][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!six_n_seven_key){ six_n_seven_key = true; }
				if(!double_mode){ double_mode = true; }
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 2P 키6번
			}else if("69".equals(data.substring(4,6))){
				main_2p_old_ln[7][main_string_to_int] = data.substring(7);
				if(pms_enable){ pms_enable = false; }
				if(!six_n_seven_key){ six_n_seven_key = true; }
				if(!double_mode){ double_mode = true; }
				if(!old_long_note_type){ old_long_note_type = true; }
				// 구 롱노트 2P 키7번
			}
		}
	}
	
	if(!bms_is_zip){ bms_fileinput.close();}
	else{ bms_fileinput_zip.close(); }
}catch(IOException e){
	bms_load_complete = false;
}

max_noteline = main_string_to_int; //최대 븜스길이

%>
<%
//븜스 패턴 종류 확인

if(six_n_seven_key && !double_mode){
	bms_key_type = "7";
	stop_sequence_width_size = "281";
	
	output_width_size = "290";
}

if(!six_n_seven_key && double_mode){
	bms_key_type = "10";
	stop_sequence_width_size = "410";
	output_width_size = "415";
	stop_sequence_align = "center";
}

if(six_n_seven_key && double_mode){
	bms_key_type = "14";
	stop_sequence_width_size = "510";
	output_width_size = "515";
	stop_sequence_align = "center";
}

if(pms_enable){
	bms_key_type = "9";
	stop_sequence_width_size = "281";
	output_width_size = "290";
}


%>


<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="X-UA-Compatible" content="IE=Edge,chrome=IE9">
<title>BMS Webviewer PROTOTYPE version</title>
<link href="bms_webviewer.css" rel="stylesheet" type="text/css" />
</head>

<body>

<br>
<span style="font-size:18px;">
BMS webviewer example version<br>
<a href="bms_test.jsp?file_no=_pcm_7another.zip&line_style=<%=get_line_style%>">[롱노트 없는 7키]</a> <a href="bms_test.jsp?file_no=_hypriver_7another.zip&line_style=<%=get_line_style%>">[롱노트 다소 있는 7키]</a> <a href="bms_test.jsp?file_no=04_spl.zip&line_style=<%=get_line_style%>">[롱노트 범벅 7키]</a> <a href="bms_test.jsp?file_no=pouo_5k_L.zip&line_style=<%=get_line_style%>">[5키 패턴]</a> <a href="bms_test.jsp?file_no=_elina_for_pabat_scoreattack.zip&line_style=<%=get_line_style%>">[랜덤 (1번고정)]</a> 

<br><a href="bms_test.jsp?file_no=saki_spa.zip&line_style=<%=get_line_style%>">[구버젼 롱노트]</a> <a href="bms_test.jsp?file_no=blackf_10mainp.zip&line_style=<%=get_line_style%>">[10키 패턴]</a> <a href="bms_test.jsp?file_no=bm_lms_hardcr_14main.zip&line_style=<%=get_line_style%>">[14키 구버젼 롱노트]</a> <a href="bms_test.jsp?file_no=loli_ex.pms&line_style=<%=get_line_style%>">[9키 1]</a> <a href="bms_test.jsp?file_no=_hypr_9hyper.zip&line_style=<%=get_line_style%>">[9키 2]</a> <a href="bms_test.jsp?file_no=oc.zip&line_style=<%=get_line_style%>">[변속 및 스탑]</a>

<br>하나의 zip안에 여러가지 븜스 통합 : <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=1">[1]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=2">[2]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=3">[3]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=4">[4]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=5">[5]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=6">[6]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=7">[7]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=8">[8]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=9">[9]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=10">[10]</a> <a href="bms_test.jsp?file_no=iv_vs_pn_rmx_bbangsami_Personality_snowflower_icicle_fiary_mix.zip&line_style=<%=get_line_style%>&zipnum=11">[11]</a>
</span>
<br>
<br>
<br>라인타입 : <a href="bms_test.jsp?file_no=<%=get_file_number%>&line_style=">[BMSE타입]</a>, <a href="bms_test.jsp?file_no=<%=get_file_number%>&line_style=_4beat">[4비트]</a>, <a href="bms_test.jsp?file_no=<%=get_file_number%>&line_style=_noline">[기본보기]</a>
<br>
<br>

<% if(read_enable && (bms_is_zip || normal_file_read) && bms_load_complete){ //확장자 체크 완료 %>

<!--
우선 박자로 사이즈 맞추기 
정박시 192px
1박당 48px, 16비트 12px
-->

<%=bms_file_real_name%><br>
<%=label_player%><br>
<%=label_genre%><br>
<%=label_title%><br>
<%=label_artist%><br>
<%=label_bpm%><br>
<%=label_playlevel%><br>
<%=label_rank%><br>
<%=label_totals%><br>
<%=label_difficulty%><br>
<%=label_subartist%><br>
<%=label_lnobj%><br>


<div class="bms_webviewer_box" style="width:<%=output_width_size%>px;">
<%

double now_bakja = 1.0;
int now_bakja_height = 192;

int divide_note_line = 1;
int divide_note_position = 0;
int long_note_continue = 0;

int divide_note_line_2p = 1;
int divide_note_position_2p = 0;
int long_note_continue_2p = 0;
boolean long_note[] = new boolean[20];	// 0:1P스크, 1:1P 1번키...순으로
boolean long_note_old_ln[] = new boolean[20];	// 0:1P스크, 1:1P 1번키...순으로
boolean last_long_note = false;

for(int now_i = max_noteline; now_i >= 0 ; now_i--){
	now_bakja = 1.0;
	now_bakja_height = 192;
	
	divide_note_line = 1;
	
	//박자 변경
	if(main_bakja[now_i] != null){
		try{
			now_bakja = Double.parseDouble(main_bakja[now_i]);
			now_bakja_height = (int)(192*(float)now_bakja);
		}catch(Exception e){
			now_bakja = 1.0;
			now_bakja_height = 192;
		}
	}
	
%>







<!-- bpm 및 stop 표시 -->
<%
	if((bpm_change && (bpm_change_old_type || bpm_change_new_type)) || (exist_stop && stop_sequence)){
		%>
<div class="line_bpm_and_stop" style="height:<%=now_bakja_height%>px;">
        <%
		if(bpm_change_old_type){
			//구형부터 출력 (16진수)
			
			//배치준비
			divide_note_line = 1;
			divide_note_position = 0;
			if(main_bpm_change_small[now_i] != null){
				try{
					divide_note_line = (main_bpm_change_small[now_i].length())/2;
					for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
						try{
							divide_note_position += (now_bakja_height/divide_note_line);
							if(!"00".equals(main_bpm_change_small[now_i].substring(sc_i-2,sc_i))){
								//bpm정보있음
								%>
                                <div class="note_bpm_empty" style="height:<%=divide_note_position-12%>px;"></div>
                                <% try{ %>
									<div class="note_bpm" align="center"><%=Integer.parseInt(main_bpm_change_small[now_i].substring(sc_i-2,sc_i), 16)%></div>
                                <% }catch(NumberFormatException numa){ %>
                                	<div class="note_bpm" align="center"><%=main_bpm_change_small[now_i].substring(sc_i-2,sc_i)%></div>
                                <% } %>
								<%
								divide_note_position = 0;
							}
						}catch(Exception e2){
							//에러
						}
					}
				}catch(Exception e){
					divide_note_line = 1;
				}
			}
		}
		
		
		if(bpm_change_new_type){
			//신형 출력 (16진수)
			%>
			<div class="note_bpm_absolute_line" style="height:<%=now_bakja_height%>px;">
            <%
			
			//배치준비
			divide_note_line = 1;
			divide_note_position = 0;
			if(main_bpm_change_big[now_i] != null){
				try{
					divide_note_line = (main_bpm_change_big[now_i].length())/2;
					for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
						try{
							divide_note_position += (now_bakja_height/divide_note_line);
							if(!"00".equals(main_bpm_change_big[now_i].substring(sc_i-2,sc_i))){
								//bpm정보있음
								%>
                                <div class="note_bpm_empty" style="height:<%=divide_note_position-12%>px;"></div>
                                <div class="note_bpm" align="center"><% if(float_bpm_change[count_bpm_change_now_num] % 1 != 0){ %><%=float_bpm_change[count_bpm_change_now_num]%><% }else{ %><%=(int)float_bpm_change[count_bpm_change_now_num]%><% } %></div>
								<%
								count_bpm_change_now_num--;
								divide_note_position = 0;
							}
						}catch(Exception e2){
							//에러
						}
					}
				}catch(Exception e){
					divide_note_line = 1;
				}
			}
			%>
            </div>
			<%
		}
		
		
		if(exist_stop && stop_sequence){
			//스톱 출력
			%>
			<div class="note_stop_sequence_absolute_line" style="width:<%=stop_sequence_width_size%>px; height:<%=now_bakja_height%>px;">
            <%
			
			//배치준비
			divide_note_line = 1;
			divide_note_position = 0;
			if(main_stoptime[now_i] != null){
				try{
					divide_note_line = (main_stoptime[now_i].length())/2;
					for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
						try{
							divide_note_position += (now_bakja_height/divide_note_line);
							if(!"00".equals(main_stoptime[now_i].substring(sc_i-2,sc_i))){
								//bpm정보있음
								%>
                                <div class="note_stop_sequence_empty" style="width:<%=stop_sequence_width_size%>px; height:<%=divide_note_position-14%>px;"></div>
                                <div class="note_stop_sequence" align="<%=stop_sequence_align%>" style="width:<%=stop_sequence_width_size%>px;"><% if("center".equals(stop_sequence_align)){ %>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<% } %><%=int_stoptime[count_stoptime]%></div>
								<%
								count_stoptime_now_num--;
								divide_note_position = 0;
							}
						}catch(Exception e2){
							//에러
						}
					}
				}catch(Exception e){
					divide_note_line = 1;
				}
			}
			%>
            </div>
			<%
		}
		%>
</div>
		<%
	}
%>










<!-- 5키 -->
<% if("5".equals(bms_key_type)){ // 5키로 출력 %>
	<div class="bms_note" id="notesize_5key<%=get_line_style%>" style="height:<%=now_bakja_height%>px;">
<%
for(int sc_k_no = 0; sc_k_no < 6 ; sc_k_no++){
	//css 타입 선택
	if(sc_k_no == 0){ css_block_type = "scr"; }
	else if(sc_k_no%2 == 1){ css_block_type = "whitenote"; }
	else{ css_block_type = "bluenote"; }
	%>
        <div class="line_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    <%
	
	//배치준비
	divide_note_line = 1;
	divide_note_position = 0;
	long_note_continue = 0;
	last_long_note = false;
	if(main_1p[sc_k_no][now_i] != null){
		try{
			divide_note_line = (main_1p[sc_k_no][now_i].length())/2;
			for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
				try{
					divide_note_position += (now_bakja_height/divide_note_line);
					if(!"00".equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i))){
						//노트있음
						if(label_lnobj.equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i)) && !long_note[sc_k_no]){
							//롱노트 끝점
							long_note[sc_k_no] = true;
							long_note_continue = divide_note_position;
							%>
			<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                            <%
							if(sc_i <= 2){ last_long_note = true; }
						}else if(long_note[sc_k_no]){
							//롱노트 시작점
							%>
        	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    		<%
							long_note[sc_k_no] = false;
						}else{
							//일반노트
							%>
			<div class="note_<%=css_block_type%>" style="height:<%=divide_note_position-5%>px;"></div>
							<%
						}
						divide_note_position = 0;
					}
				}catch(Exception e2){
					//에러
				}
			}
			//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
			if(long_note[sc_k_no] && !last_long_note){
				%>
                <div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                <%
			}
		}catch(Exception e){
			divide_note_line = 1;
		}
	}else if(long_note[sc_k_no]){
		//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
		%>
		<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
		<%
			
	}	// if(main_1p 닫기
	
	
	//구 롱노트 덮어씌우기
	if(old_long_note_type){
	%>
    	<div class="long_old_class_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    	<%
		divide_note_line = 1;
		divide_note_position = 0;
		long_note_continue = 0;
		last_long_note = false;
		if(main_1p_old_ln[sc_k_no][now_i] != null){
			try{
				divide_note_line = (main_1p_old_ln[sc_k_no][now_i].length())/2;
				for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
					try{
						divide_note_position += (now_bakja_height/divide_note_line);
						if(!"00".equals(main_1p_old_ln[sc_k_no][now_i].substring(sc_i-2,sc_i))){
							if(!long_note_old_ln[sc_k_no]){
								//롱노트 끝점
								long_note_old_ln[sc_k_no] = true;
								long_note_continue = divide_note_position;
								%>
                            	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
								<%
								if(sc_i <= 2){ last_long_note = true; }
							}else if(long_note_old_ln[sc_k_no]){
								//롱노트 시작점
								%>
        						<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    			<%
								long_note_old_ln[sc_k_no] = false;
							}
							divide_note_position = 0;
						}
					}catch(Exception e2){
						//에러
					}
				}
				//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
				if(long_note_old_ln[sc_k_no] && !last_long_note){
					%>
                	<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                	<%
				}	
			}catch(Exception e){
				divide_note_line = 1;
			}
		}else if(long_note_old_ln[sc_k_no]){
			//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
			%>
			<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
			<%
			
		} // if(main_1p_old_ln 닫기
		%>
    	</div>
		<% 
	} // 구버젼 롱노트 종료 %>
        </div> <% // 라인 완성 %>
<%
}	//for sc_k_no 닫기
%> 
	</div>
    <div class="bms_viewer_nowline" align="center" style="height:<%=now_bakja_height%>px;"><%=now_i%></div>	
    
    








<!-- 7키 -->
<% }else if("7".equals(bms_key_type)){ // 7 키로 출력 %>
	<div class="bms_note" id="notesize_7key<%=get_line_style%>" style="height:<%=now_bakja_height%>px;">
<%
for(int sc_k_no = 0; sc_k_no < 8 ; sc_k_no++){
	//css 타입 선택
	if(sc_k_no == 0){ css_block_type = "scr"; }
	else if(sc_k_no%2 == 1){ css_block_type = "whitenote"; }
	else{ css_block_type = "bluenote"; }
	%>
        <div class="line_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    <%
	
	//배치준비
	divide_note_line = 1;
	divide_note_position = 0;
	long_note_continue = 0;
	last_long_note = false;
	if(main_1p[sc_k_no][now_i] != null){
		try{
			divide_note_line = (main_1p[sc_k_no][now_i].length())/2;
			for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
				try{
					divide_note_position += (now_bakja_height/divide_note_line);
					if(!"00".equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i))){
						//노트있음
						if(label_lnobj.equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i)) && !long_note[sc_k_no]){
							//롱노트 끝점
							long_note[sc_k_no] = true;
							long_note_continue = divide_note_position;
							%>
			<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                            <%
							if(sc_i <= 2){ last_long_note = true; }
						}else if(long_note[sc_k_no]){
							//롱노트 시작점
							%>
        	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    		<%
							long_note[sc_k_no] = false;
						}else{
							//일반노트
							%>
			<div class="note_<%=css_block_type%>" style="height:<%=divide_note_position-5%>px;"></div>
							<%
						}
						divide_note_position = 0;
					}
				}catch(Exception e2){
					//에러
				}
			}
			//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
			if(long_note[sc_k_no] && !last_long_note){
				%>
                <div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                <%
			}
		}catch(Exception e){
			divide_note_line = 1;
		}
	}else if(long_note[sc_k_no]){
		//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
		%>
		<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
		<%
			
	}	// if(main_1p 닫기
	
	
	//구 롱노트 덮어씌우기
	if(old_long_note_type){
	%>
    	<div class="long_old_class_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    	<%
		divide_note_line = 1;
		divide_note_position = 0;
		long_note_continue = 0;
		last_long_note = false;
		if(main_1p_old_ln[sc_k_no][now_i] != null){
			try{
				divide_note_line = (main_1p_old_ln[sc_k_no][now_i].length())/2;
				for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
					try{
						divide_note_position += (now_bakja_height/divide_note_line);
						if(!"00".equals(main_1p_old_ln[sc_k_no][now_i].substring(sc_i-2,sc_i))){
							if(!long_note_old_ln[sc_k_no]){
								//롱노트 끝점
								long_note_old_ln[sc_k_no] = true;
								long_note_continue = divide_note_position;
								%>
                            	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
								<%
								if(sc_i <= 2){ last_long_note = true; }
							}else if(long_note_old_ln[sc_k_no]){
								//롱노트 시작점
								%>
        						<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    			<%
								long_note_old_ln[sc_k_no] = false;
							}
							divide_note_position = 0;
						}
					}catch(Exception e2){
						//에러
					}
				}
				//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
				if(long_note_old_ln[sc_k_no] && !last_long_note){
					%>
                	<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                	<%
				}	
			}catch(Exception e){
				divide_note_line = 1;
			}
		}else if(long_note_old_ln[sc_k_no]){
			//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
			%>
			<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
			<%
			
		} // if(main_1p_old_ln 닫기
		%>
    	</div>
		<% 
	} // 구버젼 롱노트 종료 %>
        </div> <% // 라인 완성 %>
<%
}	//for sc_k_no 닫기
%> 
	</div>
    <div class="bms_viewer_nowline" align="center" style="height:<%=now_bakja_height%>px;"><%=now_i%></div>	
    
    
    
    
    
    
    
    
    
    
    
    
<!-- 9키 -->
<% }else if("9".equals(bms_key_type)){ // 9 키로 출력 %>
	<div class="bms_note" id="notesize_9key<%=get_line_style%>" style="height:<%=now_bakja_height%>px;">
<%
for(int sc_k_no = 1; sc_k_no < 6 ; sc_k_no++){
	//css 타입 선택
	if(sc_k_no == 0){ css_block_type = "scr"; }
	else if(sc_k_no%2 == 1){ css_block_type = "whitenote"; }
	else{ css_block_type = "bluenote"; }
	%>
        <div class="line_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    <%
	
	//배치준비
	divide_note_line = 1;
	divide_note_position = 0;
	long_note_continue = 0;
	last_long_note = false;
	if(main_1p[sc_k_no][now_i] != null){
		try{
			divide_note_line = (main_1p[sc_k_no][now_i].length())/2;
			for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
				try{
					divide_note_position += (now_bakja_height/divide_note_line);
					if(!"00".equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i))){
						//노트있음
						if(label_lnobj.equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i)) && !long_note[sc_k_no]){
							//롱노트 끝점
							long_note[sc_k_no] = true;
							long_note_continue = divide_note_position;
							%>
			<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                            <%
							if(sc_i <= 2){ last_long_note = true; }
						}else if(long_note[sc_k_no]){
							//롱노트 시작점
							%>
        	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    		<%
							long_note[sc_k_no] = false;
						}else{
							//일반노트
							%>
			<div class="note_<%=css_block_type%>" style="height:<%=divide_note_position-5%>px;"></div>
							<%
						}
						divide_note_position = 0;
					}
				}catch(Exception e2){
					//에러
				}
			}
			//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
			if(long_note[sc_k_no] && !last_long_note){
				%>
                <div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                <%
			}
		}catch(Exception e){
			divide_note_line = 1;
		}
	}else if(long_note[sc_k_no]){
		//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
		%>
		<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
		<%
			
	}	// if(main_1p 닫기
	
	
	//구 롱노트 덮어씌우기
	if(old_long_note_type){
	%>
    	<div class="long_old_class_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    	<%
		divide_note_line = 1;
		divide_note_position = 0;
		long_note_continue = 0;
		last_long_note = false;
		if(main_1p_old_ln[sc_k_no][now_i] != null){
			try{
				divide_note_line = (main_1p_old_ln[sc_k_no][now_i].length())/2;
				for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
					try{
						divide_note_position += (now_bakja_height/divide_note_line);
						if(!"00".equals(main_1p_old_ln[sc_k_no][now_i].substring(sc_i-2,sc_i))){
							if(!long_note_old_ln[sc_k_no]){
								//롱노트 끝점
								long_note_old_ln[sc_k_no] = true;
								long_note_continue = divide_note_position;
								%>
                            	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
								<%
								if(sc_i <= 2){ last_long_note = true; }
							}else if(long_note_old_ln[sc_k_no]){
								//롱노트 시작점
								%>
        						<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    			<%
								long_note_old_ln[sc_k_no] = false;
							}
							divide_note_position = 0;
						}
					}catch(Exception e2){
						//에러
					}
				}
				//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
				if(long_note_old_ln[sc_k_no] && !last_long_note){
					%>
                	<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                	<%
				}	
			}catch(Exception e){
				divide_note_line = 1;
			}
		}else if(long_note_old_ln[sc_k_no]){
			//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
			%>
			<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
			<%
			
		} // if(main_1p_old_ln 닫기
		%>
    	</div>
		<% 
	} // 구버젼 롱노트 종료 %>
        </div> <% // 라인 완성 %>
<%
}	//for sc_k_no 닫기


for(int sc_k_no = 2; sc_k_no < 6 ; sc_k_no++){
	//css 타입 선택
	if(sc_k_no == 0){ css_block_type = "scr"; }
	else if(sc_k_no%2 == 1){ css_block_type = "whitenote"; }
	else{ css_block_type = "bluenote"; }
	%>
        <div class="line_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    <%
	
	//배치준비
	divide_note_line = 1;
	divide_note_position = 0;
	long_note_continue = 0;
	last_long_note = false;
	if(main_2p[sc_k_no][now_i] != null){
		try{
			divide_note_line = (main_2p[sc_k_no][now_i].length())/2;
			for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
				try{
					divide_note_position += (now_bakja_height/divide_note_line);
					if(!"00".equals(main_2p[sc_k_no][now_i].substring(sc_i-2,sc_i))){
						//노트있음
						if(label_lnobj.equals(main_2p[sc_k_no][now_i].substring(sc_i-2,sc_i)) && !long_note[sc_k_no]){
							//롱노트 끝점
							long_note[sc_k_no] = true;
							long_note_continue = divide_note_position;
							%>
			<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                            <%
							if(sc_i <= 2){ last_long_note = true; }
						}else if(long_note[sc_k_no]){
							//롱노트 시작점
							%>
        	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    		<%
							long_note[sc_k_no] = false;
						}else{
							//일반노트
							%>
			<div class="note_<%=css_block_type%>" style="height:<%=divide_note_position-5%>px;"></div>
							<%
						}
						divide_note_position = 0;
					}
				}catch(Exception e2){
					//에러
				}
			}
			//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
			if(long_note[sc_k_no] && !last_long_note){
				%>
                <div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                <%
			}
		}catch(Exception e){
			divide_note_line = 1;
		}
	}else if(long_note[sc_k_no]){
		//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
		%>
		<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
		<%
			
	}	// if(main_2p 닫기
	
	
	//구 롱노트 덮어씌우기
	if(old_long_note_type){
	%>
    	<div class="long_old_class_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    	<%
		divide_note_line = 1;
		divide_note_position = 0;
		long_note_continue = 0;
		last_long_note = false;
		if(main_2p_old_ln[sc_k_no][now_i] != null){
			try{
				divide_note_line = (main_2p_old_ln[sc_k_no][now_i].length())/2;
				for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
					try{
						divide_note_position += (now_bakja_height/divide_note_line);
						if(!"00".equals(main_2p_old_ln[sc_k_no][now_i].substring(sc_i-2,sc_i))){
							if(!long_note_old_ln[sc_k_no]){
								//롱노트 끝점
								long_note_old_ln[sc_k_no] = true;
								long_note_continue = divide_note_position;
								%>
                            	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
								<%
								if(sc_i <= 2){ last_long_note = true; }
							}else if(long_note_old_ln[sc_k_no]){
								//롱노트 시작점
								%>
        						<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    			<%
								long_note_old_ln[sc_k_no] = false;
							}
							divide_note_position = 0;
						}
					}catch(Exception e2){
						//에러
					}
				}
				//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
				if(long_note_old_ln[sc_k_no] && !last_long_note){
					%>
                	<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                	<%
				}	
			}catch(Exception e){
				divide_note_line = 1;
			}
		}else if(long_note_old_ln[sc_k_no]){
			//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
			%>
			<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
			<%
			
		} // if(main_2p_old_ln 닫기
		%>
    	</div>
		<% 
	} // 구버젼 롱노트 종료 %>
        </div> <% // 라인 완성 %>
<%
}	//for sc_k_no 닫기
%> 
	</div>
    <div class="bms_viewer_nowline" align="center" style="height:<%=now_bakja_height%>px;"><%=now_i%></div>	
    
    
    
    
    
    
    
    
    
    
    
    
  <!-- 10키 -->
<% }else if("10".equals(bms_key_type)){ // 5 키로 출력 %>
	<div class="bms_note" id="notesize_5key<%=get_line_style%>" style="height:<%=now_bakja_height%>px;">
<%
for(int sc_k_no = 0; sc_k_no < 6 ; sc_k_no++){
	//css 타입 선택
	if(sc_k_no == 0){ css_block_type = "scr"; }
	else if(sc_k_no%2 == 1){ css_block_type = "whitenote"; }
	else{ css_block_type = "bluenote"; }
	%>
        <div class="line_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    <%
	
	//배치준비
	divide_note_line = 1;
	divide_note_position = 0;
	long_note_continue = 0;
	last_long_note = false;
	if(main_1p[sc_k_no][now_i] != null){
		try{
			divide_note_line = (main_1p[sc_k_no][now_i].length())/2;
			for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
				try{
					divide_note_position += (now_bakja_height/divide_note_line);
					if(!"00".equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i))){
						//노트있음
						if((label_lnobj.equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i))) && !long_note[sc_k_no]){
							//롱노트 끝점
							long_note[sc_k_no] = true;
							long_note_continue = divide_note_position;
							%>
			<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                            <%
							if(sc_i <= 2){ last_long_note = true; }
						}else if(long_note[sc_k_no]){
							//롱노트 시작점
							%>
        	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    		<%
							long_note[sc_k_no] = false;
						}else{
							//일반노트
							%>
			<div class="note_<%=css_block_type%>" style="height:<%=divide_note_position-5%>px;"></div>
							<%
						}
						divide_note_position = 0;
					}
				}catch(Exception e2){
					//에러
				}
			}
			//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
			if(long_note[sc_k_no] && !last_long_note){
				%>
                <div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                <%
			}	
		}catch(Exception e){
			divide_note_line = 1;
		}
	}else if(long_note[sc_k_no]){
		//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
		%>
		<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
		<%
			
	}	// if(main_1p 닫기
	
	
	//구 롱노트 덮어씌우기
	if(old_long_note_type){
	%>
    	<div class="long_old_class_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    	<%
		divide_note_line = 1;
		divide_note_position = 0;
		long_note_continue = 0;
		last_long_note = false;
		if(main_1p_old_ln[sc_k_no][now_i] != null){
			try{
				divide_note_line = (main_1p_old_ln[sc_k_no][now_i].length())/2;
				for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
					try{
						divide_note_position += (now_bakja_height/divide_note_line);
						if(!"00".equals(main_1p_old_ln[sc_k_no][now_i].substring(sc_i-2,sc_i))){
							if(!long_note_old_ln[sc_k_no]){
								//롱노트 끝점
								long_note_old_ln[sc_k_no] = true;
								long_note_continue = divide_note_position;
								%>
                            	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
								<%
								if(sc_i <= 2){ last_long_note = true; }
							}else if(long_note_old_ln[sc_k_no]){
								//롱노트 시작점
								%>
        						<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    			<%
								long_note_old_ln[sc_k_no] = false;
							}
							divide_note_position = 0;
						}
					}catch(Exception e2){
						//에러
					}
				}
				//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
				if(long_note_old_ln[sc_k_no] && !last_long_note){
					%>
                	<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                	<%
				}	
			}catch(Exception e){
				divide_note_line = 1;
			}
		}else if(long_note_old_ln[sc_k_no]){
			//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
			%>
			<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
			<%
			
		} // if(main_1p_old_ln 닫기
			
		%>
    	</div>
		<% 
	} // 구버젼 롱노트 종료 %>
    
        </div> <% // 라인 완성 %>
<%
}	//for sc_k_no 닫기
%> 
	</div>
    <div class="bms_viewer_nowline" align="center" style="height:<%=now_bakja_height%>px;"><%=now_i%></div>	
  <div class="bms_note_right" id="notesize_5key_right_sc<%=get_line_style%>" style="height:<%=now_bakja_height%>px;">
<%
for(int sc_k_no2 = 1; sc_k_no2 < 7 ; sc_k_no2++){
	//css 타입 선택
	if(sc_k_no2 == 6){ sc_k_no2 = 0; }
	if(sc_k_no2 == 0){ css_block_type = "scr"; }
	else if(sc_k_no2%2 == 1){ css_block_type = "whitenote"; }
	else{ css_block_type = "bluenote"; }
	%>
        <div class="line_<%=css_block_type%>_right" style="height:<%=now_bakja_height%>px;">
    <%
	
	//배치준비
	divide_note_line_2p = 1;
	divide_note_position_2p = 0;
	long_note_continue_2p = 0;
	last_long_note = false;
	if(main_2p[sc_k_no2][now_i] != null){
		try{
			divide_note_line_2p = (main_2p[sc_k_no2][now_i].length())/2;
			for(int sc_i = divide_note_line_2p*2 ; sc_i >= 1 ; sc_i-=2){
				try{
					divide_note_position_2p += (now_bakja_height/divide_note_line_2p);
					if(!"00".equals(main_2p[sc_k_no2][now_i].substring(sc_i-2,sc_i))){
						//노트있음
						if(label_lnobj.equals(main_2p[sc_k_no2][now_i].substring(sc_i-2,sc_i)) && !long_note[sc_k_no2 + 10]){
							//롱노트 끝점
							long_note[sc_k_no2 + 10] = true;
							long_note_continue_2p = divide_note_position_2p;
							%>
			<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                            <%
							if(sc_i <= 2){ last_long_note = true; }
						}else if(long_note[sc_k_no2 + 10]){
							//롱노트 시작점
							%>
        	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    		<%
							long_note[sc_k_no2 + 10] = false;
						}else{
							//일반노트
							%>
			<div class="note_<%=css_block_type%>" style="height:<%=divide_note_position_2p-5%>px;"></div>
							<%
						}
						divide_note_position_2p = 0;
					}
				}catch(Exception e2){
					//에러
				}
			}
			//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
			if(long_note[sc_k_no2 + 10] && !last_long_note){
				%>
                <div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue_2p)%>px;"></div>
                <%
			}
		}catch(Exception e){
			divide_note_line_2p = 1;
		}
	}else if(long_note[sc_k_no2 + 10]){
		//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
		%>
		<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
		<%
			
	}	// if(main_1p 닫기
	
	
	
	//구 롱노트 덮어씌우기
	if(old_long_note_type){
	%>
    	<div class="long_old_class_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    	<%
		divide_note_line = 1;
		divide_note_position = 0;
		long_note_continue = 0;
		last_long_note = false;
		if(main_2p_old_ln[sc_k_no2][now_i] != null){
			try{
				divide_note_line = (main_2p_old_ln[sc_k_no2][now_i].length())/2;
				for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
					try{
						divide_note_position += (now_bakja_height/divide_note_line);
						if(!"00".equals(main_2p_old_ln[sc_k_no2][now_i].substring(sc_i-2,sc_i))){
							if(!long_note_old_ln[sc_k_no2 + 10]){
								//롱노트 끝점
								long_note_old_ln[sc_k_no2 + 10] = true;
								long_note_continue = divide_note_position;
								%>
                            	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
								<%
								if(sc_i <= 2){ last_long_note = true; }
							}else if(long_note_old_ln[sc_k_no2 + 10]){
								//롱노트 시작점
								%>
        						<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    			<%
								long_note_old_ln[sc_k_no2 + 10] = false;
							}
							divide_note_position = 0;
						}
					}catch(Exception e2){
						//에러
					}
				}
				//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
				if(long_note_old_ln[sc_k_no2 + 10] && !last_long_note){
					%>
                	<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                	<%
				}	
			}catch(Exception e){
				divide_note_line = 1;
			}
		}else if(long_note_old_ln[sc_k_no2 + 10]){
			//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
			%>
			<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
			<%
			
		} // if(main_2p_old_ln 닫기
			
		%>
    	</div>
		<% 
	} // 구버젼 롱노트 종료 %>
        </div> <% // 라인 완성 %>
<%
	if(sc_k_no2 == 0){ sc_k_no2 = 6; }
}	//for sc_k_no2 닫기
%> 
	</div>
    
    
    
    
    
    
    
    
    
    
    <!-- 14키 -->
<% }else if("14".equals(bms_key_type)){ // 7 키로 출력 %>
  <div class="bms_note" id="notesize_7key<%=get_line_style%>" style="height:<%=now_bakja_height%>px;">
<%
for(int sc_k_no = 0; sc_k_no < 8 ; sc_k_no++){
	//css 타입 선택
	if(sc_k_no == 0){ css_block_type = "scr"; }
	else if(sc_k_no%2 == 1){ css_block_type = "whitenote"; }
	else{ css_block_type = "bluenote"; }
	%>
        <div class="line_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    <%
	
	//배치준비
	divide_note_line = 1;
	divide_note_position = 0;
	long_note_continue = 0;
	last_long_note = false;
	if(main_1p[sc_k_no][now_i] != null){
		try{
			divide_note_line = (main_1p[sc_k_no][now_i].length())/2;
			for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
				try{
					divide_note_position += (now_bakja_height/divide_note_line);
					if(!"00".equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i))){
						//노트있음
						if((label_lnobj.equals(main_1p[sc_k_no][now_i].substring(sc_i-2,sc_i))) && !long_note[sc_k_no]){
							//롱노트 끝점
							long_note[sc_k_no] = true;
							long_note_continue = divide_note_position;
							%>
			<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                            <%
							if(sc_i <= 2){ last_long_note = true; }
						}else if(long_note[sc_k_no]){
							//롱노트 시작점
							%>
        	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    		<%
							long_note[sc_k_no] = false;
						}else{
							//일반노트
							%>
			<div class="note_<%=css_block_type%>" style="height:<%=divide_note_position-5%>px;"></div>
							<%
						}
						divide_note_position = 0;
					}
				}catch(Exception e2){
					//에러
				}
			}
			//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
			if(long_note[sc_k_no] && !last_long_note){
				%>
                <div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                <%
			}	
		}catch(Exception e){
			divide_note_line = 1;
		}
	}else if(long_note[sc_k_no]){
		//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
		%>
		<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
		<%
			
	}	// if(main_1p 닫기
	
	
	//구 롱노트 덮어씌우기
	if(old_long_note_type){
	%>
    	<div class="long_old_class_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    	<%
		divide_note_line = 1;
		divide_note_position = 0;
		long_note_continue = 0;
		last_long_note = false;
		if(main_1p_old_ln[sc_k_no][now_i] != null){
			try{
				divide_note_line = (main_1p_old_ln[sc_k_no][now_i].length())/2;
				for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
					try{
						divide_note_position += (now_bakja_height/divide_note_line);
						if(!"00".equals(main_1p_old_ln[sc_k_no][now_i].substring(sc_i-2,sc_i))){
							if(!long_note_old_ln[sc_k_no]){
								//롱노트 끝점
								long_note_old_ln[sc_k_no] = true;
								long_note_continue = divide_note_position;
								%>
                            	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
								<%
								if(sc_i <= 2){ last_long_note = true; }
							}else if(long_note_old_ln[sc_k_no]){
								//롱노트 시작점
								%>
        						<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    			<%
								long_note_old_ln[sc_k_no] = false;
							}
							divide_note_position = 0;
						}
					}catch(Exception e2){
						//에러
					}
				}
				//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
				if(long_note_old_ln[sc_k_no] && !last_long_note){
					%>
                	<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                	<%
				}	
			}catch(Exception e){
				divide_note_line = 1;
			}
		}else if(long_note_old_ln[sc_k_no]){
			//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
			%>
			<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
			<%
			
		} // if(main_1p_old_ln 닫기
			
		%>
    	</div>
		<% 
	} // 구버젼 롱노트 종료 %>
    
        </div> <% // 라인 완성 %>
<%
}	//for sc_k_no 닫기
%> 
	</div>
    <div class="bms_viewer_nowline" align="center" style="height:<%=now_bakja_height%>px;"><%=now_i%></div>	
  <div class="bms_note_right" id="notesize_7key_right_sc<%=get_line_style%>" style="height:<%=now_bakja_height%>px;">
<%
for(int sc_k_no2 = 1; sc_k_no2 < 9 ; sc_k_no2++){
	//css 타입 선택
	if(sc_k_no2 == 8){ sc_k_no2 = 0; }
	if(sc_k_no2 == 0){ css_block_type = "scr"; }
	else if(sc_k_no2%2 == 1){ css_block_type = "whitenote"; }
	else{ css_block_type = "bluenote"; }
	%>
        <div class="line_<%=css_block_type%>_right" style="height:<%=now_bakja_height%>px;">
    <%
	
	//배치준비
	divide_note_line_2p = 1;
	divide_note_position_2p = 0;
	long_note_continue_2p = 0;
	last_long_note = false;
	if(main_2p[sc_k_no2][now_i] != null){
		try{
			divide_note_line_2p = (main_2p[sc_k_no2][now_i].length())/2;
			for(int sc_i = divide_note_line_2p*2 ; sc_i >= 1 ; sc_i-=2){
				try{
					divide_note_position_2p += (now_bakja_height/divide_note_line_2p);
					if(!"00".equals(main_2p[sc_k_no2][now_i].substring(sc_i-2,sc_i))){
						//노트있음
						if(label_lnobj.equals(main_2p[sc_k_no2][now_i].substring(sc_i-2,sc_i)) && !long_note[sc_k_no2 + 10]){
							//롱노트 끝점
							long_note[sc_k_no2 + 10] = true;
							long_note_continue_2p = divide_note_position_2p;
							%>
			<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                            <%
							if(sc_i <= 2){ last_long_note = true; }
						}else if(long_note[sc_k_no2 + 10]){
							//롱노트 시작점
							%>
        	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    		<%
							long_note[sc_k_no2 + 10] = false;
						}else{
							//일반노트
							%>
			<div class="note_<%=css_block_type%>" style="height:<%=divide_note_position_2p-5%>px;"></div>
							<%
						}
						divide_note_position_2p = 0;
					}
				}catch(Exception e2){
					//에러
				}
			}
			//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
			if(long_note[sc_k_no2 + 10] && !last_long_note){
				%>
                <div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue_2p)%>px;"></div>
                <%
			}
		}catch(Exception e){
			divide_note_line_2p = 1;
		}
	}else if(long_note[sc_k_no2 + 10]){
		//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
		%>
		<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
		<%
			
	}	// if(main_1p 닫기
	
	
	
	//구 롱노트 덮어씌우기
	if(old_long_note_type){
	%>
    	<div class="long_old_class_<%=css_block_type%>" style="height:<%=now_bakja_height%>px;">
    	<%
		divide_note_line = 1;
		divide_note_position = 0;
		long_note_continue = 0;
		last_long_note = false;
		if(main_2p_old_ln[sc_k_no2][now_i] != null){
			try{
				divide_note_line = (main_2p_old_ln[sc_k_no2][now_i].length())/2;
				for(int sc_i = divide_note_line*2 ; sc_i >= 1 ; sc_i-=2){
					try{
						divide_note_position += (now_bakja_height/divide_note_line);
						if(!"00".equals(main_2p_old_ln[sc_k_no2][now_i].substring(sc_i-2,sc_i))){
							if(!long_note_old_ln[sc_k_no2 + 10]){
								//롱노트 끝점
								long_note_old_ln[sc_k_no2 + 10] = true;
								long_note_continue = divide_note_position;
								%>
                            	<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
								<%
								if(sc_i <= 2){ last_long_note = true; }
							}else if(long_note_old_ln[sc_k_no2 + 10]){
								//롱노트 시작점
								%>
        						<div class="note_<%=css_block_type%><% if(divide_note_line > 31){ %>_short<% } %>" id="note_<%=css_block_type%>_long_color" style="height:<% if(divide_note_line > 31){ %><%=divide_note_position-1%><% }else{ %><%=divide_note_position-5%><% } %>px;"></div>
                    			<%
								long_note_old_ln[sc_k_no2 + 10] = false;
							}
							divide_note_position = 0;
						}
					}catch(Exception e2){
						//에러
					}
				}
				//for 종료후에도 롱노트가 종료되지 않았을경우 메꾸기
				if(long_note_old_ln[sc_k_no2 + 10] && !last_long_note){
					%>
                	<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=(now_bakja_height-long_note_continue)%>px;"></div>
                	<%
				}	
			}catch(Exception e){
				divide_note_line = 1;
			}
		}else if(long_note_old_ln[sc_k_no2 + 10]){
			//노트가 없지만 롱노트가 안끝난 빈라인일때 라인 메꾸기
			%>
			<div class="note_<%=css_block_type%>_long_continue" id="note_<%=css_block_type%>_long_color" style="height:<%=now_bakja_height%>px;"></div>
			<%
			
		} // if(main_2p_old_ln 닫기
			
		%>
    	</div>
		<% 
	} // 구버젼 롱노트 종료 %>
        </div> <% // 라인 완성 %>
<%
	if(sc_k_no2 == 0){ sc_k_no2 = 8; }
}	//for sc_k_no2 닫기
%> 
	</div>
    
    
<%
}	//if bms_key_type 닫기 (키 선택)
}	//for max_noteline 닫기 (모두 출력완료)
%>
</div>    
  
  
<% }else{ %>    
<div>
BMS파일을 읽어올 수 없습니다.
파일이 존재하지 않거나 일시적 오류일 수 있습니다.
</div>
<% } //확장자 체크 완료 종료 %>    


</body>
</html>
