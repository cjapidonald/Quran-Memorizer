#!/usr/bin/env ruby
# frozen_string_literal: true
#
# odr_tagging.rb
#
# Purpose:
#   Programmatically add On-Demand Resources (ODR) tags to audio files in an
#   Xcode project using the `xcodeproj` gem.
#
# What it does:
#   • Ensures ENABLE_ON_DEMAND_RESOURCES = YES on the chosen target
#   • Scans your project for audio files under your chosen folders (e.g. "Quranvn/Mishary"
#     and "Quranvn/Saad") and assigns a tag per file:
#       Quranvn/Mishary/001.mp3  -> tag "mishary-001"
#       Quranvn/Saad/114.mp3     -> tag "saad-114"
#   • If files exist on disk but are not yet in the project, the script can add
#     them to the Resources build phase automatically (opt-in with --add-missing)
#
# Requirements:
#   gem install xcodeproj
#
# Usage examples:
#   ruby odr_tagging.rb \
#     --project "/Users/donaldcjapi/Desktop/Quran Memorizer/Quran Memorizer.xcodeproj" \
#     --target  "Quran Memorizer" \
#     --mishary-dir "Quranvn/Mishary" \
#     --saad-dir    "Quranvn/Saad"
#
require 'optparse'
require 'pathname'
require 'fileutils'
begin
  require 'xcodeproj'
rescue LoadError
  abort "Missing dependency 'xcodeproj'. Install with: gem install xcodeproj"
end

options = {
  project: nil,
  target_name: nil,
  mishary_dir: 'Quranvn/Mishary',
  saad_dir: 'Quranvn/Saad',
  add_missing: false,
  dry_run: false
}

op = OptionParser.new do |opts|
  opts.banner = "Usage: ruby odr_tagging.rb [options]"
  opts.on("-p", "--project PATH", "Path to .xcodeproj") { |v| options[:project] = v }
  opts.on("-t", "--target NAME",  "Target name (app target)") { |v| options[:target_name] = v }
  opts.on("--mishary-dir PATH",   "Folder for Mishary audio (relative to project or absolute)") { |v| options[:mishary_dir] = v }
  opts.on("--saad-dir PATH",      "Folder for Saad audio (relative to project or absolute)")    { |v| options[:saad_dir] = v }
  opts.on("--add-missing",        "Add files that exist on disk but aren't in the project")     { options[:add_missing] = true }
  opts.on("--dry-run",            "Don't save changes; just print what would happen")           { options[:dry_run] = true }
  opts.on("-h", "--help",         "Show help") { puts opts; exit }
end
op.parse!

def abort_with_usage(op, msg)
  warn msg
  warn op
  exit 1
end

abort_with_usage(op, "✖︎ --project is required") unless options[:project]
abort_with_usage(op, "✖︎ --target is required")  unless options[:target_name]
project_path = Pathname.new(options[:project])
abort "✖︎ Project not found: #{project_path}" unless project_path.exist?
abort "✖︎ Not an .xcodeproj: #{project_path}" unless project_path.extname == ".xcodeproj"

project     = Xcodeproj::Project.open(project_path.to_s)
project_dir = project_path.dirname.realpath

# Locate target
target = project.targets.find { |t| t.name == options[:target_name] }
abort "✖︎ Target '#{options[:target_name]}' not found in project" unless target

# Ensure Resources phase
resources_phase = target.resources_build_phase || target.add_resources_build_phase

# Enable ODR at target level
target.build_configurations.each do |cfg|
  cfg.build_settings['ENABLE_ON_DEMAND_RESOURCES'] = 'YES'
end

# Helper: make a path relative to the project dir if possible
def relative_to_project(project_dir, path)
  pn = Pathname.new(path).expand_path
  begin
    pn.relative_path_from(project_dir).to_s
  rescue ArgumentError
    pn.to_s # on a different volume; absolute path fallback
  end
end

# Helper: find or create a nested group by path fragments
def ensure_group(project, path_fragments)
  group = project.main_group
  path_fragments.each do |frag|
    next if frag.nil? || frag.empty?
    group = (group[frag] || group.new_group(frag))
  end
  group
end

# Helper: add file to project and to resources phase if needed
def add_or_find_file!(project, target, resources_phase, display_group, abs_path, project_dir)
  rel = relative_to_project(project_dir, abs_path)
  file_ref = display_group.files.find { |f| f.path == rel || f.path == abs_path || File.basename(f.path) == File.basename(abs_path) }
  file_ref ||= display_group.new_file(rel)

  build_file = resources_phase.files.find { |bf| bf.file_ref == file_ref }
  build_file ||= resources_phase.add_file_reference(file_ref, true)
  [file_ref, build_file]
end

def sanitize_tag(tag)
  tag.strip.downcase.gsub(/[^a-z0-9._-]+/, '-')
end

def tag_for(reciter, filename_wo_ext)
  sanitize_tag("#{reciter}-#{filename_wo_ext}")
end

def assign_tag!(build_file, tag)
  build_file.settings ||= {}
  existing = Array(build_file.settings['ASSET_TAGS']).map(&:to_s)
  unless existing.include?(tag)
    build_file.settings['ASSET_TAGS'] = (existing + [tag]).uniq
    return :changed
  end
  :unchanged
end

# Derive group path fragments from provided directory
def group_fragments_for_dir(dir_path, project_dir, fallback_group)
  p = Pathname.new(dir_path)
  if p.absolute?
    begin
      rel = p.expand_path.relative_path_from(project_dir).to_s
      rel.split(/[\/\\]+/)
    rescue ArgumentError
      [fallback_group] # outside project
    end
  else
    dir_path.split(/[\/\\]+/)
  end
end

added   = 0
tagged  = 0
skipped = 0

reciters = [
  ['mishary', options[:mishary_dir]],
  ['saad',    options[:saad_dir]]
]

reciters.each do |reciter_name, dir|
  dir_path = Pathname.new(dir)
  dir_path = (dir_path.absolute? ? dir_path : project_dir.join(dir_path))
  unless dir_path.directory?
    warn "⚠︎ Skipping #{reciter_name}: directory not found: #{dir_path}"
    next
  end

  # Build group path based on the provided directory (e.g., "Quranvn/Mishary")
  fragments = group_fragments_for_dir(dir, project_dir, "Linked Audio") # keeps "Quranvn", "Mishary"
  display_group = ensure_group(project, fragments)

  Dir.glob(dir_path.join('**/*.{mp3,m4a,wav,aac,mp4}')).sort.each do |abs_file|
    bn     = File.basename(abs_file, '.*')
    tag    = tag_for(reciter_name, bn)

    existing_bf = resources_phase.files.find do |bf|
      fr = bf.file_ref
      next false unless fr
      File.basename(fr.path.to_s) == File.basename(abs_file) &&
        fr.real_path.exist? &&
        fr.real_path.expand_path.to_s == Pathname.new(abs_file).expand_path.to_s
    end

    build_file = existing_bf
    if build_file.nil?
      if options[:add_missing]
        _file_ref, build_file = add_or_find_file!(project, target, resources_phase, display_group, abs_file, project_dir)
        added += 1
        puts "➕ Added to project: #{abs_file}"
      else
        skipped += 1
        puts "• Exists on disk but not in project (use --add-missing): #{abs_file}"
        next
      end
    end

    if assign_tag!(build_file, tag) == :changed
      tagged += 1
      puts "🏷️  Tagged: #{File.basename(abs_file)} -> #{tag}"
    else
      puts "✓ Already tagged: #{File.basename(abs_file)} (#{Array(build_file.settings['ASSET_TAGS']).join(', ')})"
    end
  end
end

puts "\nSummary:"
puts "  Files added to project: #{added}"
puts "  Files tagged/updated:   #{tagged}"
puts "  Files skipped:          #{skipped}"

if options[:dry_run]
  puts "\n--dry-run enabled: not saving project."
else
  project.save
  puts "✅ Saved changes to project: #{project_path}"
end

puts "\nNext steps:"
puts "  • In Xcode, select your app target → Build Settings → ensure 'Enable On Demand Resources' is YES."
puts "  • Optionally set 'On Demand Resources Initial Install Tags' for any packs you want preinstalled."
puts "  • Request your audio at runtime with NSBundleResourceRequest(tags: [\"mishary-001\"])."
