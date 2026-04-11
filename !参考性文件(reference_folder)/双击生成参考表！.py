import sqlite3
import os
import sys

# 尝试导入 pandas 和 openpyxl 用于导出 Excel
try:
    import pandas as pd
    HAS_PANDAS = True
except ImportError:
    HAS_PANDAS = False
    import csv

def generate_reference_tables():
    # 1. 设置路径（相对于当前脚本所在目录）
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sql_file_path = os.path.abspath(os.path.join(script_dir, "..", "MAB_CORE_TABLE_INFO.sql"))
    output_dir = os.path.join(script_dir, "refer_table-参考表")
    
    if not os.path.exists(sql_file_path):
        print(f"错误：未找到 SQL 文件：{sql_file_path}")
        return

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(f"正在读取 SQL 文件: {sql_file_path}")

    # 2. 初始化内存数据库
    conn = sqlite3.connect(":memory:")
    cursor = conn.cursor()

    # 3. 创建 Mock 游戏表并填充硬编码的原版数据
    # 创建表结构
    cursor.execute("CREATE TABLE GreatPersonClasses (GreatPersonClassType TEXT)")
    cursor.execute("CREATE TABLE Resources (ResourceType TEXT, ResourceClassType TEXT)")
    cursor.execute("CREATE TABLE GlobalParameters (Name TEXT, Value TEXT)")

    # 硬编码的原版伟人数据
    great_persons = [
        'GREAT_PERSON_CLASS_GENERAL',
        'GREAT_PERSON_CLASS_ADMIRAL',
        'GREAT_PERSON_CLASS_ENGINEER',
        'GREAT_PERSON_CLASS_MERCHANT',
        'GREAT_PERSON_CLASS_PROPHET',
        'GREAT_PERSON_CLASS_SCIENTIST',
        'GREAT_PERSON_CLASS_WRITER',
        'GREAT_PERSON_CLASS_ARTIST',
        'GREAT_PERSON_CLASS_MUSICIAN'
    ]
    for gp in great_persons:
        cursor.execute("INSERT INTO GreatPersonClasses VALUES (?)", (gp,))

    # 硬编码的原版战略资源数据
    strategic_resources = [
        'RESOURCE_ALUMINUM',
        'RESOURCE_COAL',
        'RESOURCE_HORSES',
        'RESOURCE_IRON',
        'RESOURCE_NITER',
        'RESOURCE_OIL',
        'RESOURCE_URANIUM'
    ]
    for res in strategic_resources:
        cursor.execute("INSERT INTO Resources VALUES (?, 'RESOURCECLASS_STRATEGIC')", (res,))

    print(f"已预载 {len(great_persons)} 个伟人类和 {len(strategic_resources)} 个战略资源数据。")

    # 4. 执行 SQL 文件
    with open(sql_file_path, 'r', encoding='utf-8') as f:
        sql_script = f.read()
        
    try:
        # sqlite3 的 executescript 可以一次性执行多条语句
        cursor.executescript(sql_script)
        print("SQL 执行成功！")
    except sqlite3.Error as e:
        print(f"执行 SQL 时出错: {e}")
        print("尝试继续导出已加载的数据...")

    # 5. 导出目标表格
    target_tables = [
        "Ruivo_AdjacencyType",
        "Ruivo_ModifierOwner_CollectionType",
        "Ruivo_ProvideType_YieldType"
    ]

    for table_name in target_tables:
        try:
            # 检查表是否存在
            cursor.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table_name}'")
            if not cursor.fetchone():
                print(f"跳过：表 {table_name} 未在 SQL 中定义。")
                continue

            # 获取数据
            cursor.execute(f"SELECT * FROM {table_name}")
            rows = cursor.fetchall()
            # 获取列名
            columns = [description[0] for description in cursor.description]

            if HAS_PANDAS:
                # 使用 Pandas 导出 Excel
                df = pd.DataFrame(rows, columns=columns)
                excel_path = os.path.join(output_dir, f"{table_name}.xlsx")
                df.to_excel(excel_path, index=False)
                print(f"成功导出 Excel: {excel_path}")
            else:
                # 降级使用 CSV 导出
                csv_path = os.path.join(output_dir, f"{table_name}.csv")
                with open(csv_path, 'w', newline='', encoding='utf-8-sig') as f:
                    writer = csv.writer(f)
                    writer.writerow(columns)
                    writer.writerows(rows)
                print(f"成功导出 CSV (未安装 pandas): {csv_path}")

        except Exception as e:
            print(f"导出表 {table_name} 时出错: {e}")

    conn.close()
    print("\n所有任务已完成！表格保存在 '参考表输出' 文件夹中。")
    input("按回车键退出...")

if __name__ == "__main__":
    generate_reference_tables()
