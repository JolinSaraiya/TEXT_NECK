import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine
} from 'recharts';

const PostureChart = ({ data }) => {
  return (
    <div className="chart-container glass-panel animate-fade-in" style={{ padding: '1.5rem', height: '400px' }}>
      <h3 style={{ marginBottom: '1.5rem', color: 'var(--text-primary)' }}>Posture Improvement Over Time</h3>
      <ResponsiveContainer width="100%" height="100%">
        <LineChart
          data={data}
          margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
        >
          <CartesianGrid strokeDasharray="3 3" stroke="hsla(220, 20%, 30%, 0.3)" />
          <XAxis 
            dataKey="date" 
            stroke="var(--text-secondary)" 
            tick={{ fill: 'var(--text-secondary)' }} 
          />
          <YAxis 
            stroke="var(--text-secondary)" 
            tick={{ fill: 'var(--text-secondary)' }}
            label={{ value: 'Angle (°)', angle: -90, position: 'insideLeft', fill: 'var(--text-secondary)' }}
          />
          <Tooltip 
            contentStyle={{ 
              backgroundColor: 'var(--bg-color)', 
              borderColor: 'var(--surface-border)',
              borderRadius: '8px'
            }} 
            itemStyle={{ color: 'var(--accent-teal)' }}
          />
          {/* Threshold line for severe posture */}
          <ReferenceLine y={30} label="Severe Threshold" stroke="var(--danger-red)" strokeDasharray="3 3" />
          
          <Line 
            type="monotone" 
            dataKey="average_angle" 
            stroke="var(--accent-teal)" 
            strokeWidth={3}
            activeDot={{ r: 8 }} 
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
};

export default PostureChart;
