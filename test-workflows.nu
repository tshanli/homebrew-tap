#!/usr/bin/env nu

# Test script for running GitHub Actions workflows locally with act
# Cross-platform Nushell version that works on Windows, macOS, and Linux

def main [] {
  print "🧪 Homebrew Tap Workflow Testing with Act"
  print "================================================="

  # Check if act is installed
  if not (which act | is-not-empty) {
    print ((ansi red) + "[ERROR]" + (ansi reset) + " act is not installed. Install it with: brew install act (or appropriate package manager)")
    exit 1
  }

  # Check if Docker is running (cross-platform)
  let docker_check = try { docker info } | complete
  if $docker_check.exit_code != 0 {
    print ((ansi red) + "[ERROR]" + (ansi reset) + " Docker is not running. Please start Docker Desktop.")
    exit 1
  }

  print ((ansi blue) + "[NOTE]" + (ansi reset) + " Updated workflow structure: All workflows now at top level (.github/workflows/)")
  print ((ansi blue) + "[NOTE]" + (ansi reset) + " This ensures compatibility with GitHub Actions reusable workflow requirements")

  # Common act options for consistency
  let act_opts = ["--container-architecture" "linux/amd64" "--artifact-server-path" "/tmp/artifacts"]

  # Create test directories (cross-platform)
  mkdir ("/tmp/act-test-logs" | path expand)
  mkdir ("/tmp/artifacts" | path expand)

  print ((ansi green) + "[INFO]" + (ansi reset) + " Available test options:")
  print "1. 🧪 Test all workflows (dry run)"
  print "2. 🎯 Choose specific workflow"

  let choice = input "Choose an option (1-2): "

  match $choice {
    "1" => { test_all_workflows $act_opts }
    "2" => { choose_specific_workflow $act_opts }
    _ => {
      print ((ansi red) + "[ERROR]" + (ansi reset) + " Invalid option")
      exit 1
    }
  }

  print ""
  print ((ansi green) + "[INFO]" + (ansi reset) + " Test completed!")
  print ((ansi blue) + "[NOTE]" + (ansi reset) + " Remember: Some workflows may fail due to external dependencies (GitHub API, etc.)")
  print ((ansi blue) + "[NOTE]" + (ansi reset) + " Use dry-run mode (-n flag) for syntax validation without execution")
  print ((ansi blue) + "[NOTE]" + (ansi reset) + " Logs are available in /tmp/act-test-logs and artifacts in /tmp/artifacts")
}

def test_all_workflows [act_opts: list<string>] {
  print ((ansi green) + "[INFO]" + (ansi reset) + " Testing all workflows (syntax validation)...")

  mut workflows_found = false

  # Check Formula directory and test corresponding workflows
  if ("Formula" | path exists) {
    let formulas = glob "Formula/*.rb" | each {|formula|
      $formula | path basename | str replace ".rb" ""
    }

    for formula_name in $formulas {
      let workflow_file = (".github/workflows/update-" + $formula_name + ".yml")
      if ($workflow_file | path exists) {
        print ((ansi green) + "[INFO]" + (ansi reset) + "   → Testing Formula/" + $formula_name + " workflow...")
        run_act_command $workflow_file $act_opts
        $workflows_found = true
      }
    }
  }

  # Check Casks directory and test corresponding workflows
  if ("Casks" | path exists) {
    let casks = glob "Casks/*.rb" | each {|cask|
      $cask | path basename | str replace ".rb" ""
    }

    for cask_name in $casks {
      let workflow_file = (".github/workflows/update-" + $cask_name + ".yml")
      if ($workflow_file | path exists) {
        print ((ansi green) + "[INFO]" + (ansi reset) + "   → Testing Casks/" + $cask_name + " workflow...")
        run_act_command $workflow_file $act_opts
        $workflows_found = true
      }
    }
  }

  # Check for update-formulas.yml (orchestrator workflow)
  if (".github/workflows/update-formulas.yml" | path exists) {
    print ((ansi green) + "[INFO]" + (ansi reset) + "   → Testing Update All workflow...")
    let cmd = ["act" "workflow_dispatch" "-n" "-W" ".github/workflows/update-formulas.yml"] ++ $act_opts ++ ["--input" "formula=all"]
    run-external ...$cmd
    $workflows_found = true
  }

  if not $workflows_found {
    print ((ansi red) + "[ERROR]" + (ansi reset) + " No workflows found to test")
    exit 1
  }
}

def choose_specific_workflow [act_opts: list<string>] {
  print "Choose which workflow to test:"

  mut options = []
  mut choice_map = {}
  mut counter = 1

  # Check Formula directory
  if ("Formula" | path exists) {
    let formulas = glob "Formula/*.rb" | each {|formula|
      $formula | path basename | str replace ".rb" ""
    }

    for formula_name in $formulas {
      print ("  " + ($counter | into string) + ") Formula/" + $formula_name)
      $options = ($options | append $counter)
      $choice_map = ($choice_map | insert ($counter | into string) ("formula:" + $formula_name))
      $counter = ($counter + 1)
    }
  }

  # Check Casks directory
  if ("Casks" | path exists) {
    let casks = glob "Casks/*.rb" | each {|cask|
      $cask | path basename | str replace ".rb" ""
    }

    for cask_name in $casks {
      print ("  " + ($counter | into string) + ") Casks/" + $cask_name)
      $options = ($options | append $counter)
      $choice_map = ($choice_map | insert ($counter | into string) ("cask:" + $cask_name))
      $counter = ($counter + 1)
    }
  }

  if ($options | length) == 0 {
    print ((ansi red) + "[ERROR]" + (ansi reset) + " No formulas or casks found")
    exit 1
  }

  let min_option = ($options | math min)
  let max_option = ($options | math max)
  let workflow_choice = input ("Enter choice (" + ($min_option | into string) + "-" + ($max_option | into string) + "): ")

  # Validate choice
  let choice_num = try { $workflow_choice | into int } | default (-1)
  if not ($choice_num in $options) {
    print ((ansi red) + "[ERROR]" + (ansi reset) + " Invalid workflow choice")
    exit 1
  }

  # Parse the choice
  let choice_data = $choice_map | get ($choice_num | into string)
  let choice_parts = $choice_data | split row ":"
  let choice_type = $choice_parts | get 0
  let package_name = $choice_parts | get 1

  match $choice_type {
    "formula" => {
      print ((ansi green) + "[INFO]" + (ansi reset) + " Testing Formula/" + $package_name + " workflow...")
      let workflow_file = ("update-" + $package_name + ".yml")
      let full_path = (".github/workflows/" + $workflow_file)
      if ($full_path | path exists) {
        run_act_command $full_path $act_opts
      } else {
        print ((ansi red) + "[ERROR]" + (ansi reset) + " Workflow file " + $workflow_file + " not found")
        exit 1
      }
    }
    "cask" => {
      print ((ansi green) + "[INFO]" + (ansi reset) + " Testing Casks/" + $package_name + " workflow...")
      let workflow_file = ("update-" + $package_name + ".yml")
      let full_path = (".github/workflows/" + $workflow_file)
      if ($full_path | path exists) {
        run_act_command $full_path $act_opts
      } else {
        print ((ansi red) + "[ERROR]" + (ansi reset) + " Workflow file " + $workflow_file + " not found")
        exit 1
      }
    }
  }
}

def run_act_command [workflow_file: string act_opts: list<string>] {
  let cmd = ["act" "workflow_dispatch" "-n" "-W" $workflow_file] ++ $act_opts
  run-external ...$cmd
}
