#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Markdown 轉 HTML 轉換器
支援 Mermaid 流程圖和完整的 Markdown 語法

使用方法:
    python md_to_html.py input.md [output.html]
    
如果沒有指定輸出檔案，會自動產生同名的 .html 檔案
"""

import os
import sys
import re
import argparse
from pathlib import Path
import markdown
from markdown.extensions import codehilite, tables, toc, fenced_code
from markdown.extensions.wikilinks import WikiLinkExtension

def get_html_template():
    """返回 HTML 模板"""
    return """<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/mermaid/10.6.1/mermaid.min.js"></script>
    <style>
        /* 基本樣式 */
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            max-width: 900px;
            margin: 0 auto;
            padding: 40px 20px;
            line-height: 1.6;
            color: #333;
            background-color: #fafafa;
        }}
        
        /* 內容容器 */
        .container {{
            background: white;
            padding: 40px;
            border-radius: 12px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
        }}
        
        /* 標題樣式 */
        h1, h2, h3, h4, h5, h6 {{
            margin-top: 2rem;
            margin-bottom: 1rem;
            font-weight: 600;
            line-height: 1.25;
            color: #2c3e50;
        }}
        
        h1 {{
            font-size: 2.5rem;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
            margin-bottom: 2rem;
        }}
        
        h2 {{
            font-size: 2rem;
            border-bottom: 2px solid #ecf0f1;
            padding-bottom: 8px;
        }}
        
        h3 {{
            font-size: 1.5rem;
            color: #e74c3c;
        }}
        
        /* 段落和文字 */
        p {{
            margin-bottom: 1rem;
            text-align: justify;
        }}
        
        /* 程式碼樣式 */
        code {{
            background: #f8f9fa;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'SF Mono', 'Monaco', 'Inconsolata', 'Fira Code', monospace;
            font-size: 0.9em;
            color: #e74c3c;
        }}
        
        pre {{
            background: #2c3e50;
            color: #ecf0f1;
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 20px 0;
            border-left: 4px solid #3498db;
        }}
        
        pre code {{
            background: transparent;
            padding: 0;
            color: #ecf0f1;
            font-size: 0.9rem;
        }}
        
        /* 列表樣式 */
        ul, ol {{
            margin-left: 2rem;
            margin-bottom: 1rem;
        }}
        
        li {{
            margin-bottom: 0.5rem;
        }}
        
        /* 引用塊 */
        blockquote {{
            border-left: 4px solid #3498db;
            padding: 10px 20px;
            margin: 20px 0;
            background: #f8f9fa;
            font-style: italic;
            color: #555;
        }}
        
        /* 表格樣式 */
        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }}
        
        th, td {{
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ecf0f1;
        }}
        
        th {{
            background: #3498db;
            color: white;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.9rem;
            letter-spacing: 0.5px;
        }}
        
        tr:hover {{
            background: #f8f9fa;
        }}
        
        /* 連結樣式 */
        a {{
            color: #3498db;
            text-decoration: none;
            border-bottom: 1px solid transparent;
            transition: all 0.3s ease;
        }}
        
        a:hover {{
            color: #2980b9;
            border-bottom-color: #2980b9;
        }}
        
        /* Mermaid 圖表容器 */
        .mermaid {{
            text-align: center;
            margin: 30px 0;
            background: white;
            padding: 20px;
            border-radius: 8px;
            border: 1px solid #e1e8ed;
        }}
        
        /* 水平線 */
        hr {{
            border: none;
            height: 2px;
            background: linear-gradient(to right, transparent, #3498db, transparent);
            margin: 2rem 0;
        }}
        
        /* 圖片樣式 */
        img {{
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
            margin: 20px 0;
        }}
        
        /* 目錄樣式 */
        .toc {{
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }}
        
        .toc ul {{
            list-style-type: none;
            margin-left: 0;
        }}
        
        .toc a {{
            color: #495057;
            text-decoration: none;
        }}
        
        /* 響應式設計 */
        @media (max-width: 768px) {{
            body {{
                padding: 20px 10px;
            }}
            
            .container {{
                padding: 20px;
            }}
            
            h1 {{
                font-size: 2rem;
            }}
            
            h2 {{
                font-size: 1.5rem;
            }}
            
            table {{
                font-size: 0.9rem;
            }}
            
            th, td {{
                padding: 8px 10px;
            }}
        }}
        
        /* 程式碼高亮樣式 */
        .codehilite {{
            background: #2c3e50;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            overflow-x: auto;
        }}
        
        .codehilite pre {{
            background: transparent;
            border: none;
            margin: 0;
            padding: 0;
        }}
    </style>
</head>
<body>
    <div class="container">
        {content}
    </div>
    
    <script>
        // 初始化 Mermaid
        mermaid.initialize({{ 
            startOnLoad: true,
            theme: 'default',
            themeVariables: {{
                fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif',
                fontSize: '16px'
            }}
        }});
    </script>
</body>
</html>"""

def process_mermaid_blocks(content):
    """處理 Mermaid 程式碼塊，將其轉換為 Mermaid 圖表"""
    def replace_mermaid(match):
        code = match.group(1).strip()
        return f'<div class="mermaid">\n{code}\n</div>'
    
    # 替換 ```mermaid ... ``` 為 Mermaid 圖表
    pattern = r'```mermaid\n(.*?)```'
    return re.sub(pattern, replace_mermaid, content, flags=re.DOTALL)

def markdown_to_html(md_content, title="Markdown 文檔"):
    """將 Markdown 內容轉換為 HTML"""
    
    # 預處理 Mermaid 程式碼塊
    md_content = process_mermaid_blocks(md_content)
    
    # 配置 Markdown 擴展
    extensions = [
        'markdown.extensions.extra',      # 支援表格、定義列表等
        'markdown.extensions.codehilite', # 程式碼高亮
        'markdown.extensions.toc',        # 目錄
        'markdown.extensions.fenced_code', # 圍欄程式碼塊
        'markdown.extensions.tables',     # 表格支援
    ]
    
    # 擴展配置
    extension_configs = {
        'markdown.extensions.codehilite': {
            'css_class': 'codehilite',
            'use_pygments': False  # 使用內建樣式
        },
        'markdown.extensions.toc': {
            'permalink': True,
            'toc_depth': 6
        }
    }
    
    # 建立 Markdown 處理器
    md = markdown.Markdown(
        extensions=extensions,
        extension_configs=extension_configs
    )
    
    # 轉換為 HTML
    html_content = md.convert(md_content)
    
    # 生成完整的 HTML 文檔
    full_html = get_html_template().format(
        title=title,
        content=html_content
    )
    
    return full_html

def convert_file(input_file, output_file=None):
    """轉換單個檔案"""
    input_path = Path(input_file)
    
    if not input_path.exists():
        raise FileNotFoundError(f"找不到輸入檔案: {input_file}")
    
    if not input_path.suffix.lower() in ['.md', '.markdown']:
        raise ValueError("輸入檔案必須是 .md 或 .markdown 格式")
    
    # 確定輸出檔案名
    if output_file is None:
        output_file = input_path.with_suffix('.html')
    else:
        output_file = Path(output_file)
    
    # 讀取 Markdown 檔案
    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            md_content = f.read()
    except UnicodeDecodeError:
        with open(input_path, 'r', encoding='utf-8-sig') as f:
            md_content = f.read()
    
    # 使用檔案名作為標題
    title = input_path.stem.replace('_', ' ').replace('-', ' ').title()
    
    # 轉換為 HTML
    html_content = markdown_to_html(md_content, title)
    
    # 寫入輸出檔案
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    return output_file

def main():
    """主函數"""
    parser = argparse.ArgumentParser(
        description='將 Markdown 檔案轉換為 HTML（支援 Mermaid 流程圖）',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
範例:
    python md_to_html.py document.md
    python md_to_html.py document.md output.html
    python md_to_html.py *.md
        """
    )
    
    parser.add_argument('input', nargs='+', help='輸入的 Markdown 檔案')
    parser.add_argument('-o', '--output', help='輸出的 HTML 檔案（單個檔案時）')
    parser.add_argument('-v', '--verbose', action='store_true', help='顯示詳細資訊')
    
    args = parser.parse_args()
    
    # 處理多個檔案
    if len(args.input) > 1 and args.output:
        print("❌ 錯誤: 處理多個檔案時不能指定輸出檔案名")
        sys.exit(1)
    
    success_count = 0
    total_count = len(args.input)
    
    for input_file in args.input:
        try:
            # 支援萬用字元
            input_paths = list(Path('.').glob(input_file)) if '*' in input_file else [Path(input_file)]
            
            for input_path in input_paths:
                if args.verbose:
                    print(f"📄 處理檔案: {input_path}")
                
                output_path = convert_file(
                    str(input_path), 
                    args.output if len(args.input) == 1 else None
                )
                
                if args.verbose:
                    print(f"✅ 轉換完成: {input_path} → {output_path}")
                    file_size = output_path.stat().st_size
                    print(f"📊 輸出檔案大小: {file_size:,} bytes")
                else:
                    print(f"✅ {input_path} → {output_path}")
                
                success_count += 1
                
        except Exception as e:
            print(f"❌ 處理檔案 {input_file} 時發生錯誤: {e}")
    
    print(f"\n🎉 轉換完成! 成功處理 {success_count} 個檔案")

if __name__ == '__main__':
    # 檢查必要套件
    try:
        import markdown
    except ImportError:
        print("❌ 錯誤: 需要安裝 markdown 套件")
        print("請執行: pip install markdown")
        sys.exit(1)
    
    main()
