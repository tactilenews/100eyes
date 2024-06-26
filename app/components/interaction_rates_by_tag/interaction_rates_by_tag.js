import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['barChart'];
  static values = {
    url: String,
  };

  connect() {
    console.log('im connected');
    this.fetchBarChartData(this.urlValue);
  }

  async fetchBarChartData(endpoint) {
    const response = await fetch(endpoint);
    const jsonResponse = await response.json();
    const options = this.setupBarChart(jsonResponse);
    this.renderChart(options);
  }

  setupBarChart(jsonResponse) {
    const fontStyles = {
      style: {
        fontSize: '16px',
        fontFamily: 'Inter, Helvetica Neue, Helvetica, sans-serif',
      },
    };

    return {
      chart: {
        type: 'bar',
      },
      plotOptions: {
        bar: {
          horizontal: true,
        },
      },
      series: jsonResponse,
      xaxis: {
        labels: {
          ...fontStyles,
        },
        title: {
          ...fontStyles,
          text: 'Interaktion',
        },
      },
      yaxis: {
        labels: {
          ...fontStyles,
        },
        title: {
          ...fontStyles,
          text: 'Tags',
        },
      },
      colors: ['#ff00a0'],
      legend: {
        ...fontStyles.style,
        position: 'bottom',
        markers: {
          width: 16,
          height: 16,
          radius: 16,
        },
        itemMargin: {
          horizontal: 10,
        },
      },
    };
  }

  renderChart(options) {
    const chart = new window.ApexCharts(this.barChartTarget, options);
    if (chart) {
      chart.render();
    }
  }
}
