package member;


public class bms_webview{
	
	public String uploaded_or_link(String file_name){
		try{
			if(file_name.length() > 8 && "append_".equals(file_name.substring(0,7))){
				file_name = "append_bms/" + file_name;
			}
		}catch(Exception e){ }
		return file_name;
	}
	
	public boolean external_or_self(String file_name){
		try{
			if(file_name.length() > 8 && "append_".equals(file_name.substring(0,7))){
				return false;
			}
		}catch(Exception e){ return true; }
		return true;
	}
	
	public String level_type_star_or_button(String level_type, String key_type){
		try{
			if(level_type.length() >= 2){
				if("a".equals(level_type.substring(0,1))){
					if("e".equals(key_type)){
						level_type = "○" + level_type.substring(1);
					}else if("a".equals(key_type) || "b".equals(key_type) || "c".equals(key_type) || "d".equals(key_type)){
						level_type = "☆" + level_type.substring(1);
					}else{ level_type = ""; }
				}else if("b".equals(level_type.substring(0,1))){
					if("e".equals(key_type)){
						level_type = "●" + level_type.substring(1);
					}else if("a".equals(key_type) || "b".equals(key_type) || "c".equals(key_type) || "d".equals(key_type)){
						level_type = "★" + level_type.substring(1);
					}else { level_type = ""; }
				}else{
					level_type = "";
				}
			}else{
				level_type = "";
			}
		}catch(Exception lte){ level_type = ""; }
		return level_type;
	}
	
	public String key_type_to_lang(String key_type, String dic48, String dic46, String dic47){
		if("a".equals(key_type)){ key_type = "5" + dic48; }
		else if("b".equals(key_type)){ key_type = "7" + dic48; }
		else if("c".equals(key_type)){ key_type = "10" + dic48; }
		else if("d".equals(key_type)){ key_type = "14" + dic48; }
		else if("e".equals(key_type)){ key_type = "9" + dic48; }
		else if("f".equals(key_type)){ key_type = dic46; }
		else if("g".equals(key_type)){ key_type = "BGA"; }
		else if("h".equals(key_type)){ key_type = dic47; }
		else{ key_type = "z"; }
		return key_type;
	}

	
}