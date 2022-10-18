import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['heatmap', 'repliesButton', 'requestsButton'];
  static classes = ['active'];
  static values = {
    repliesChartUrl: String,
    requestsChartUrl: String,
  };

  connect() {
    this.renderRepliesChart();
  }

  async fetchTimeBasedActivityData(endpoint) {
    const response = await fetch(endpoint);
    const jsonResponse = await response.json();
    const options = this.setUpChart(jsonResponse);
    this.renderChart(options);
  }

  setUpChart(jsonResponse) {
    const series = [
      'Sonntag',
      'Samstag',
      'Freitag',
      'Donnerstag',
      'Mittwoch',
      'Dienstag',
      'Montag',
    ].map(day => ({ name: day, data: [] }));
    Object.entries(jsonResponse).map(([key, value]) => {
      series.map(object => {
        if (JSON.parse(key)[0] == object.name) {
          object.data.push({ x: JSON.parse(key)[1], y: value });
        }
      });
    });

    return {
      chart: {
        type: 'heatmap',
      },
      series: series,
      plotOptions: {
        heatmap: {
          colorScale: {
            ranges: [
              {
                from: 0,
                to: 5,
                color: '#F8C8DC',
                name: 'Keine oder wenig',
              },
              {
                from: 6,
                to: 20,
                color: '#FFB6C1',
                name: 'Leicht',
              },
              {
                from: 21,
                to: 45,
                color: '#FF00A0',
                name: 'Mittel',
              },
              {
                from: 46,
                to: 100,
                color: '#f4177a',
                name: 'Hoch',
              },
              {
                from: 101,
                to: 200,
                color: '#FF1493',
                name: 'Extrem',
              },
              {
                from: 201,
                to: 1000,
                color: '#C71585',
                name: 'Höchste',
              },
            ],
          },
        },
      },
    };
  }

  renderChart(options) {
    const chart = new window.ApexCharts(this.heatmapTarget, options);
    if (chart) {
      this.heatmapTarget.innerHTML = '';
      chart.render();
    }
  }

  renderRepliesChart() {
    this.requestsButtonTarget.classList.remove(this.activeClass);
    this.repliesButtonTarget.classList.add(this.activeClass);
    this.fetchTimeBasedActivityData(this.repliesChartUrlValue);
  }

  renderRequestsChart() {
    this.repliesButtonTarget.classList.remove(this.activeClass);
    this.requestsButtonTarget.classList.add(this.activeClass);
    this.fetchTimeBasedActivityData(this.requestsChartUrlValue);
  }
}
