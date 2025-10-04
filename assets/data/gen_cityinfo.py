import requests
import json
import time
import os
import shutil
from datetime import datetime
from typing import List, Dict

def safe_fetch_data(url: str, max_retries: int = 3) -> str:
    """安全获取数据，带重试机制"""
    for retry in range(max_retries):
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            response = requests.get(url, headers=headers, timeout=15)
            response.encoding = 'utf-8'
            
            data = response.text.strip()
            if data and '|' in data:
                return data
                
        except Exception as e:
            print(f"第{retry+1}次尝试失败: {url}, 错误: {e}")
            if retry < max_retries - 1:
                time.sleep(2)
            continue
    
    return ""

def parse_text_data(data: str) -> List[Dict[str, str]]:
    """解析文本格式的数据"""
    result = []
    if not data:
        return result
    
    try:
        # 处理类似 "01|北京,02|上海" 的格式
        items = data.split(',')
        for item in items:
            if '|' in item:
                parts = item.split('|')
                if len(parts) == 2:
                    code = parts[0].strip()
                    name = parts[1].strip()
                    if code and name:
                        result.append({'code': code, 'name': name})
    except Exception as e:
        print(f"解析数据失败: {e}, 数据: {data[:100]}")
    
    return result

def build_weather_code(area_code: str) -> str:
    """构建天气代码"""
    # 根据你提供的例子，中国代码 + 区域代码
    # 比如安徽安庆望江的代码是220607，天气代码是101220607
    return f"101{area_code}"

def get_districts_data() -> List[Dict[str, str]]:
    """获取所有区县数据"""
    final_result = []
    
    # 获取省份数据（使用你提供的示例数据作为备份）
    province_url = "http://www.weather.com.cn/data/list3/city.xml?level=1"
    province_data = safe_fetch_data(province_url)
    
    # 如果获取失败，使用你提供的示例数据
    if not province_data:
        province_data = "01|北京,02|上海,03|天津,04|重庆,05|黑龙江,06|吉林,07|辽宁,08|内蒙古,09|河北,10|山西,11|陕西,12|山东,13|新疆,14|西藏,15|青海,16|甘肃,17|宁夏,18|河南,19|江苏,20|湖北,21|浙江,22|安徽,23|福建,24|江西,25|湖南,26|贵州,27|四川,28|广东,29|云南,30|广西,31|海南,32|香港,33|澳门,34|台湾"
    
    provinces = parse_text_data(province_data)
    print(f"获取到 {len(provinces)} 个省份")
    
    total_districts = 0
    
    # 遍历省份
    for i, province in enumerate(provinces):
        province_code = province['code']
        province_name = province['name']
        
        print(f"处理省份 {i+1}/{len(provinces)}: {province_name}")
        
        # 获取城市数据
        city_url = f"http://www.weather.com.cn/data/list3/city{province_code}.xml?level=2"
        city_data = safe_fetch_data(city_url)
        
        if not city_data:
            continue
            
        cities = parse_text_data(city_data)
        
        # 遍历城市
        for city in cities:
            city_code = city['code']
            city_name = city['name']
            
            # 获取区县数据
            district_url = f"http://www.weather.com.cn/data/list3/city{city_code}.xml?level=3"
            district_data = safe_fetch_data(district_url)
            
            if not district_data:
                continue
                
            districts = parse_text_data(district_data)
            
            # 添加到最终结果
            for district in districts:
                weather_code = build_weather_code(district['code'])
                final_result.append({
                    'id': weather_code,
                    'name': district['name']
                })
                total_districts += 1
        
        # 每处理5个省份暂停一下，避免请求过于频繁
        if (i + 1) % 5 == 0:
            time.sleep(1)
    
    print(f"总共获取到 {total_districts} 个区县")
    return final_result

def backup_existing_file(file_path: str) -> str:
    """备份已存在的文件"""
    if os.path.exists(file_path):
        # 生成备份文件名，格式：原文件名.YYYYMMDD
        timestamp = datetime.now().strftime("%Y%m%d")
        backup_path = f"{file_path}.{timestamp}"
        
        # 如果备份文件已存在，添加序号
        counter = 1
        original_backup_path = backup_path
        while os.path.exists(backup_path):
            backup_path = f"{original_backup_path}.{counter}"
            counter += 1
        
        # 复制文件
        shutil.copy2(file_path, backup_path)
        print(f"已备份原文件到: {backup_path}")
        return backup_path
    
    return ""

def main():
    """主函数"""
    print("开始获取天气区县数据...")
    
    # 获取所有第三级数据
    districts = get_districts_data()
    
    # 保存为JSON文件
    output_file = "city.json"
    
    # 如果文件已存在，先备份
    backup_file = backup_existing_file(output_file)
    
    # 保存新数据（紧凑格式，一行一个城市）
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('[\n')
        for i, district in enumerate(districts):
            city_line = f'  {{"id":"{district["id"]}","name":"{district["name"]}"}}'
            if i < len(districts) - 1:
                city_line += ','
            f.write(city_line + '\n')
        f.write(']')
    
    print(f"数据已保存到 {output_file}")
    if backup_file:
        print(f"原文件已备份为: {backup_file}")
    
    # 显示统计信息
    print(f"\n数据统计:")
    print(f"- 总记录数: {len(districts)}")
    if districts:
        print(f"- 第一条记录: {districts[0]}")
        print(f"- 最后一条记录: {districts[-1]}")

if __name__ == "__main__":
    main()