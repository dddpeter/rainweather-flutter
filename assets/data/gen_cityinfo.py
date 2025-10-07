import requests
import json
import time
import os
import shutil
from datetime import datetime
from typing import List, Dict, Tuple

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

def validate_city_id(city_id: str, max_retries: int = 2) -> Tuple[bool, str]:
    """验证城市ID是否有效，通过调用天气API"""
    for retry in range(max_retries):
        try:
            url = f"https://www.weatherol.cn/api/home/getCurrAnd15dAnd24h?cityid={city_id}"
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            response = requests.get(url, headers=headers, timeout=5)
            
            if response.status_code == 200:
                data = response.json()
                # 检查响应是否包含有效的天气数据
                if data.get('code') == 200 and data.get('data'):
                    return True, "有效"
                else:
                    return False, f"API返回错误: {data.get('message', '未知错误')}"
            else:
                return False, f"HTTP错误: {response.status_code}"
                
        except Exception as e:
            if retry < max_retries - 1:
                time.sleep(0.5)
                continue
            return False, f"请求异常: {str(e)}"
    
    return False, "验证失败"

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

def get_districts_data(validate_data: bool = False) -> List[Dict[str, str]]:
    """获取所有区县数据，并可选择验证数据有效性"""
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
    valid_count = 0
    invalid_count = 0
    
    # 遍历省份
    for i, province in enumerate(provinces):
        province_code = province['code']
        province_name = province['name']
        
        print(f"\n处理省份 {i+1}/{len(provinces)}: {province_name}")
        
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
                district_name = district['name']
                weather_code = build_weather_code(district['code'])
                
                # 如果需要验证数据
                is_valid = True
                if validate_data:
                    is_valid, message = validate_city_id(weather_code)
                    if is_valid:
                        valid_count += 1
                        print(f"  ✅ {district_name} ({weather_code})")
                    else:
                        invalid_count += 1
                        print(f"  ❌ {district_name} ({weather_code}) - {message}")
                    
                    # 避免请求过于频繁
                    time.sleep(0.2)
                
                # 只添加有效的数据
                if is_valid:
                    final_result.append({
                        'id': weather_code,
                        'name': district_name,
                        'province': province_name,
                        'city': city_name
                    })
                    total_districts += 1
        
        # 每处理5个省份暂停一下，避免请求过于频繁
        if (i + 1) % 5 == 0:
            time.sleep(2)
    
    print(f"\n总共获取到 {total_districts} 个区县")
    if validate_data:
        print(f"验证统计: 有效 {valid_count}, 无效 {invalid_count}")
        if valid_count + invalid_count > 0:
            print(f"有效率: {valid_count/(valid_count+invalid_count)*100:.1f}%")
    
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
    print("=" * 60)
    
    # 询问是否需要验证数据
    validate = input("\n是否验证数据有效性？(会调用API验证每个城市，耗时较长) [y/N]: ").strip().lower()
    should_validate = validate in ['y', 'yes']
    
    if should_validate:
        print("\n⚠️  警告: 验证模式将调用API验证每个城市，预计需要20-30分钟")
        confirm = input("确认继续? [y/N]: ").strip().lower()
        if confirm not in ['y', 'yes']:
            print("已取消验证，将不验证数据")
            should_validate = False
    
    # 获取所有第三级数据
    districts = get_districts_data(validate_data=should_validate)
    
    if not districts:
        print("❌ 未获取到任何数据，程序退出")
        return
    
    # 保存为JSON文件
    output_file = "city.json"
    
    # 如果文件已存在，先备份
    backup_file = backup_existing_file(output_file)
    
    # 保存新数据（包含省、市字段，紧凑格式）
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('[\n')
        for i, district in enumerate(districts):
            city_line = f'  {{"id":"{district["id"]}","name":"{district["name"]}","province":"{district["province"]}","city":"{district["city"]}"}}'
            if i < len(districts) - 1:
                city_line += ','
            f.write(city_line + '\n')
        f.write(']')
    
    print(f"\n✅ 数据已保存到 {output_file}")
    if backup_file:
        print(f"📦 原文件已备份为: {backup_file}")
    
    # 显示统计信息
    print(f"\n" + "=" * 60)
    print(f"📊 数据统计:")
    print(f"- 总记录数: {len(districts)}")
    if districts:
        print(f"- 第一条记录: {districts[0]}")
        print(f"- 最后一条记录: {districts[-1]}")
        
        # 统计省份和城市数量
        provinces = set(d['province'] for d in districts)
        cities = set((d['province'], d['city']) for d in districts)
        print(f"- 省份数量: {len(provinces)}")
        print(f"- 城市数量: {len(cities)}")
    
    print("=" * 60)
    print("✅ 完成!")

if __name__ == "__main__":
    main()