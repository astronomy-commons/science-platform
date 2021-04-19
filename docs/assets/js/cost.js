// disable submit on 'enter' key
$('form input').on('keypress', function(e) {
    return e.which !== 13;
});

var ranges = {
    'num_users': [0, 100], 
    // 'num_spark': [0, 128], 
    'cost_user': [0, 5], 
    'cost_spark': [0, 5], 
    'cost_storage': [0, 0.5],
    'node_storage': [0, 1024],
    'user_hours': [0, 24],
    'user_days': [0, 7],
    'query_core_hours': [0, 1024]
}

var labels = {
    'num_users': "Number of Users", 
    // 'num_spark': "Number of Spark Nodes", 
    'cost_user': "Cost of User Node ($USD/hour)", 
    'cost_spark': "Cost of Spark Node ($USD/hour)", 
    'cost_storage': "Cost of Node Storage ($USD/GB/month)",
    'node_storage': "Node Storage Size (GB)",
    'user_hours': "User Hours (hours/day)",
    'user_days': "User Days (days/week)",
    'query_core_hours': "Spark Query Core Hours (core-hours/day/user)"
}

// From: https://stackoverflow.com/questions/40475155/does-javascript-have-a-method-that-returns-an-array-of-numbers-based-on-start-s
function linspace(startValue, stopValue, cardinality) {
    var arr = [];
    var step = (stopValue - startValue) / (cardinality - 1);
    for (var i = 0; i < cardinality; i++) {
      arr.push(startValue + (step * i));
    }
    return arr;
}

function cost(params) {
    var cost_user = params['cost_user']; // $USD/hour
    var cost_spark = params['cost_spark'];  // $USD/hour
    var query_core_hours = params['query_core_hours']; // core-hours/day
    var cost_storage = params['cost_storage']; // $USD/GB/month
    var node_storage = params['node_storage']; // GB
    var user_hours = params['user_hours']; // hours/day
    var user_days = params['user_days']; // days/week
    // var spark_query_hours = params['spark_query_hours']; // hours/day
    var num_users = params['num_users'];
    // var num_spark = params['num_spark'];

    var spark_node_hours = query_core_hours / 4;

    var HOURS_IN_MONTH = 24*30;
    var cost_storage_per_hour = cost_storage / HOURS_IN_MONTH;
    
    var storage_total = (
        // users
        num_users * (
            // each user each day
            node_storage * cost_storage_per_hour * (
                user_hours *  30 * (user_days / 7) + spark_node_hours
            )
        )
    )
    console.log("storage:" + storage_total);

    var vm_total = (
        // users
        num_users * (
            // each user each day
            (cost_user * user_hours * 30 * (user_days / 7))
            +
            // Spark queries for each user each day
            (cost_spark * spark_node_hours)
        ) 
    );
    console.log("vm:" + vm_total);

    return storage_total + vm_total;
}

function getInputValues() {
    var num_users_input = document.getElementById("num_users_input");
    // var num_spark_input = document.getElementById("num_spark_input");
    var cost_user_input = document.getElementById("cost_user_input");
    var cost_spark_input = document.getElementById("cost_spark_input");
    var cost_storage_input = document.getElementById("cost_storage_input");
    var node_storage_input = document.getElementById("node_storage_input");
    var user_hours_input = document.getElementById("user_hours_input");
    var user_days_input = document.getElementById("user_days_input");
    var query_core_hours_input = document.getElementById("query_core_hours_input");
    
    var num_users = parseFloat(num_users_input.value);
    // var num_spark = parseFloat(num_spark_input.value);
    var cost_user = parseFloat(cost_user_input.value);
    var cost_spark = parseFloat(cost_spark_input.value);
    var cost_storage = parseFloat(cost_storage_input.value);
    var node_storage = parseFloat(node_storage_input.value);
    var user_hours = parseFloat(user_hours_input.value);
    var user_days = parseFloat(user_days_input.value);
    var query_core_hours = parseFloat(query_core_hours_input.value);

    return {
        'num_users': num_users, 
        // 'num_spark': num_spark, 
        'cost_user': cost_user, 
        'cost_spark': cost_spark, 
        'cost_storage': cost_storage,
        'node_storage': node_storage,
        'user_hours': user_hours,
        'user_days': user_days,
        'query_core_hours': query_core_hours
    }
}

function updateCost() {
    var params = getInputValues();
    var cost_total = cost(params);
    var cost_total_span = document.getElementById("cost_total");
    cost_total_span.innerHTML = `${cost_total.toFixed(2)} ($USD/month)`;
}

const ctx = document.getElementById('chart').getContext('2d');
const chart = new Chart(ctx, {
  type: 'scatter',
  data: {
    datasets: [{
        data: [],
        label: 'Cost',
        showLine: true,
        borderColor: "rgba(0, 0, 255, 0.1)",
        // borderDash: [5, 5],
        backgroundColor: "rgba(0, 0, 255, 0.1)",
        pointBackgroundColor: "rgba(255, 0, 0, 0.1)",
        pointBorderColor: "rgba(0, 0, 255, 0.5)",
        pointHoverBackgroundColor: "rgba(0, 0, 255, 0.1)",
        pointHoverBorderColor: "rgba(255, 0, 0, 0.1)",
    }]
  },
  options: {
    responsive: true,
    scales: {
        yAxes: [{
            scaleLabel: {
              display: true,
              labelString: 'Cost ($USD/month)'
            }
        }],
        xAxes: [{
            scaleLabel: {
                display: true,
                labelString: 'none'
            }
        }]
    },
    tooltips: {
         enabled: false
    }
  }
});

function drawChart(x_axis) {
    var x_axis_name = x_axis.name.replace("_input", "");
    console.log(x_axis_name);

    var min = ranges[x_axis_name][0];
    var max = ranges[x_axis_name][1];
    var x_axis_span = linspace(min, max, 10)

    var data = [];
    var params = getInputValues();
    for (var i = 0; i < x_axis_span.length; i++) {
        params[x_axis_name] = x_axis_span[i];
        data.push({
            "x": x_axis_span[i],
            "y": cost(params)
        });
    }

    chart.data.datasets.forEach((dataset) => {
        dataset.data = data;
        dataset.label = dataset.label;
    });
    chart.options.scales.xAxes.forEach((xAxis) => {
        xAxis.scaleLabel.labelString = labels[x_axis_name];
    });
    chart.update();
}

function updateCostAndDraw(event) {
    var params = getInputValues();
    var cost_total = cost(params);
    // ensure that the cost computed is valid (not NaN)
    if (cost_total) {
        updateCost();
        var selectedOption = document.getElementById("plot_x_axis_input").value;
        if (event) {
            if (event.target.id == selectedOption) {
                return
            }
        }
        drawChart(document.getElementById(selectedOption));
    }
}

updateCostAndDraw();

$("input").on("change", updateCostAndDraw);
$("input").on("keyup", updateCostAndDraw);
$("#plot_x_axis_input").on("change", function(e) {
    console.log(e);
    console.log(this.value);
    drawChart(document.getElementById(this.value));
});