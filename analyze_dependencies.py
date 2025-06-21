#!/usr/bin/env python3
"""
Enterprise Dependency Analysis Tool
Generates comprehensive dependency graphs for the FileOrganizer Swift project
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict, deque

class SwiftDependencyAnalyzer:
    def __init__(self, project_path):
        self.project_path = Path(project_path)
        self.dependencies = defaultdict(set)
        self.imports = defaultdict(set)
        self.files = {}
        self.components = {}
        
    def analyze_file(self, file_path):
        """Analyze a single Swift file for dependencies"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Extract file name without extension
            file_name = file_path.stem
            
            # Skip test files for core architecture analysis
            if 'Test' in file_name:
                return
                
            self.files[file_name] = {
                'path': str(file_path),
                'content': content,
                'imports': [],
                'types': [],
                'dependencies': []
            }
            
            # Extract imports
            import_pattern = r'import\s+(\w+)'
            imports = re.findall(import_pattern, content)
            self.files[file_name]['imports'] = imports
            self.imports[file_name].update(imports)
            
            # Extract type definitions
            type_patterns = [
                r'class\s+(\w+)',
                r'struct\s+(\w+)',
                r'enum\s+(\w+)',
                r'protocol\s+(\w+)',
                r'extension\s+(\w+)'
            ]
            
            types = []
            for pattern in type_patterns:
                matches = re.findall(pattern, content)
                types.extend(matches)
            self.files[file_name]['types'] = types
            
            # Find references to other project types
            for other_file, other_data in self.files.items():
                if other_file != file_name:
                    for type_name in other_data['types']:
                        if re.search(r'\b' + type_name + r'\b', content):
                            self.dependencies[file_name].add(other_file)
                            
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
    
    def analyze_project(self):
        """Analyze all Swift files in the project"""
        swift_files = list(self.project_path.rglob("*.swift"))
        
        # First pass: collect all files and types
        for file_path in swift_files:
            self.analyze_file(file_path)
            
        # Second pass: find cross-references
        for file_name in list(self.files.keys()):
            content = self.files[file_name]['content']
            dependencies = []
            
            for other_file, other_data in self.files.items():
                if other_file != file_name:
                    for type_name in other_data['types']:
                        if re.search(r'\b' + type_name + r'\b', content):
                            dependencies.append(other_file)
                            
            self.files[file_name]['dependencies'] = list(set(dependencies))
            
    def categorize_components(self):
        """Categorize components based on their location and purpose"""
        categories = {
            'Core': [],
            'Views': [],
            'Models': [],
            'Services': [],
            'Intents': [],
            'Tests': []
        }
        
        for file_name, data in self.files.items():
            path = data['path']
            if '/Core/' in path:
                categories['Core'].append(file_name)
            elif '/Views/' in path:
                categories['Views'].append(file_name)
            elif '/Models/' in path:
                categories['Models'].append(file_name)
            elif '/Services/' in path:
                categories['Services'].append(file_name)
            elif '/Intents/' in path:
                categories['Intents'].append(file_name)
            elif 'Test' in file_name:
                categories['Tests'].append(file_name)
            else:
                categories['Core'].append(file_name)  # Default to Core
                
        self.components = categories
        
    def detect_circular_dependencies(self):
        """Detect circular dependencies using DFS"""
        visited = set()
        rec_stack = set()
        cycles = []
        
        def dfs(node, path):
            if node in rec_stack:
                cycle_start = path.index(node)
                cycle = path[cycle_start:] + [node]
                cycles.append(cycle)
                return
                
            if node in visited:
                return
                
            visited.add(node)
            rec_stack.add(node)
            
            for neighbor in self.files.get(node, {}).get('dependencies', []):
                dfs(neighbor, path + [node])
                
            rec_stack.remove(node)
            
        for file_name in self.files:
            if file_name not in visited:
                dfs(file_name, [])
                
        return cycles
        
    def generate_dot_graph(self, output_file='dependencies.dot'):
        """Generate Graphviz DOT file"""
        dot_content = """digraph FileOrganizerDependencies {
    rankdir=TB;
    node [shape=box, style=rounded];
    
    // Define component clusters
    subgraph cluster_core {
        label="Core Components";
        style=filled;
        color=lightblue;
        """
        
        # Add core components
        for component in self.components.get('Core', []):
            dot_content += f'        "{component}" [fillcolor=lightcyan, style=filled];\n'
            
        dot_content += """    }
    
    subgraph cluster_views {
        label="Views";
        style=filled;
        color=lightgreen;
        """
        
        # Add view components
        for component in self.components.get('Views', []):
            dot_content += f'        "{component}" [fillcolor=lightgreen, style=filled];\n'
            
        dot_content += """    }
    
    subgraph cluster_models {
        label="Models";
        style=filled;
        color=lightyellow;
        """
        
        # Add model components
        for component in self.components.get('Models', []):
            dot_content += f'        "{component}" [fillcolor=lightyellow, style=filled];\n'
            
        dot_content += """    }
    
    // Dependencies
"""
        
        # Add dependency edges
        for file_name, file_data in self.files.items():
            for dependency in file_data.get('dependencies', []):
                dot_content += f'    "{file_name}" -> "{dependency}";\n'
                
        dot_content += "}\n"
        
        with open(output_file, 'w') as f:
            f.write(dot_content)
            
        return output_file
        
    def generate_json_report(self, output_file='dependencies.json'):
        """Generate JSON report with detailed dependency information"""
        report = {
            'summary': {
                'total_files': len(self.files),
                'total_dependencies': sum(len(data['dependencies']) for data in self.files.values()),
                'components_by_category': {cat: len(files) for cat, files in self.components.items() if files}
            },
            'components': self.components,
            'files': self.files,
            'circular_dependencies': self.detect_circular_dependencies(),
            'highly_coupled_components': self.find_highly_coupled_components()
        }
        
        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)
            
        return report
        
    def find_highly_coupled_components(self, threshold=3):
        """Find components with high coupling (many dependencies)"""
        highly_coupled = []
        
        for file_name, file_data in self.files.items():
            dep_count = len(file_data.get('dependencies', []))
            if dep_count >= threshold:
                highly_coupled.append({
                    'component': file_name,
                    'dependency_count': dep_count,
                    'dependencies': file_data['dependencies']
                })
                
        return sorted(highly_coupled, key=lambda x: x['dependency_count'], reverse=True)
        
    def generate_architecture_summary(self):
        """Generate a human-readable architecture summary"""
        cycles = self.detect_circular_dependencies()
        highly_coupled = self.find_highly_coupled_components()
        
        summary = f"""
# FileOrganizer Architecture Analysis Report

## Overview
- **Total Components**: {len(self.files)}
- **Total Dependencies**: {sum(len(data['dependencies']) for data in self.files.values())}

## Component Categories
"""
        
        for category, components in self.components.items():
            if components:
                summary += f"- **{category}**: {len(components)} components\n"
                for component in components[:5]:  # Show first 5
                    summary += f"  - {component}\n"
                if len(components) > 5:
                    summary += f"  - ... and {len(components) - 5} more\n"
                summary += "\n"
                
        summary += f"""
## Circular Dependencies
{"❌ Found " + str(len(cycles)) + " circular dependencies" if cycles else "✅ No circular dependencies detected"}

"""
        
        for i, cycle in enumerate(cycles[:3]):  # Show first 3 cycles
            summary += f"**Cycle {i+1}**: {' → '.join(cycle)}\n"
            
        summary += f"""

## Highly Coupled Components (≥3 dependencies)
"""
        
        for component in highly_coupled[:5]:  # Show top 5
            summary += f"- **{component['component']}**: {component['dependency_count']} dependencies\n"
            
        return summary

def main():
    analyzer = SwiftDependencyAnalyzer("./FileOrganizer")
    
    print("🔍 Analyzing FileOrganizer dependencies...")
    analyzer.analyze_project()
    analyzer.categorize_components()
    
    print("📊 Generating dependency graph...")
    dot_file = analyzer.generate_dot_graph()
    
    print("📋 Generating JSON report...")
    json_report = analyzer.generate_json_report()
    
    print("📝 Generating architecture summary...")
    summary = analyzer.generate_architecture_summary()
    
    with open('architecture_summary.md', 'w') as f:
        f.write(summary)
        
    print("\n" + "="*60)
    print("DEPENDENCY ANALYSIS COMPLETE")
    print("="*60)
    print(summary)
    
    # Generate visual graph if dot is available
    try:
        import subprocess
        subprocess.run(['dot', '-Tpng', dot_file, '-o', 'dependencies.png'], check=True)
        subprocess.run(['dot', '-Tsvg', dot_file, '-o', 'dependencies.svg'], check=True)
        print(f"📈 Visual graphs generated: dependencies.png, dependencies.svg")
    except:
        print(f"📈 DOT file generated: {dot_file} (install Graphviz to generate visual graphs)")

if __name__ == "__main__":
    main()